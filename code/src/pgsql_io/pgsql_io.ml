let buf_size = 1024 * 8
let buf_size_threshold = 1024 * 8

exception Nested_tx_not_supported

module Backend_key_data = struct
  type t = {
    pid : int32;
    secret_key : int32;
  }
end

type t = {
  mutable connected : bool;
  decoder : Pgsql_codec.Decode.t;
  buf : Bytes.t;
  scratch : Buffer.t;
  r : Abbs_io_buffered.reader Abbs_io_buffered.t;
  w : Abbs_io_buffered.writer Abbs_io_buffered.t;
  backend_key_data : Backend_key_data.t;
  mutable unique_id : int;
  notice_response : (char * string) list -> unit;
  mutable expected_frames : (Pgsql_codec.Frame.Backend.t -> bool) list;
  mutable in_tx : bool;
  mutable busy : bool;
  buf_size_threshold : int;
}

let add_expected_frame t frame = t.expected_frames <- frame :: t.expected_frames
let add_expected_frames t frames = t.expected_frames <- List.rev frames @ t.expected_frames

let consume_expected_frames t =
  let expected_frames = t.expected_frames in
  t.expected_frames <- [];
  List.rev expected_frames

let gen_unique_id t prefix =
  let ret = prefix ^ string_of_int t.unique_id in
  t.unique_id <- t.unique_id + 1;
  ret

type integrity_err = {
  message : string;
  detail : string option;
}
[@@deriving show]

module Io = struct
  type err = [ `Parse_error of Pgsql_codec.Decode.err ] [@@deriving show]

  let encode_frame buf frame =
    Buffer.clear buf;
    Pgsql_codec.Encode.frontend_msg buf frame;
    Buffer.to_bytes buf

  let write_buf bytes = Abb_intf.Write_buf.{ buf = bytes; pos = 0; len = Bytes.length bytes }

  let send_frame conn frame =
    if conn.connected then (
      let send_frame' =
        (* Printf.printf "Tx %s\n%!" (Pgsql_codec.Frame.Frontend.show frame); *)
        let open Abbs_future_combinators.Infix_result_monad in
        let bytes = encode_frame conn.scratch frame in
        Abbs_io_buffered.write conn.w ~bufs:[ write_buf bytes ]
        >>= fun _ -> Abbs_io_buffered.flushed conn.w
      in
      let open Abb.Future.Infix_monad in
      send_frame'
      >>| function
      | Ok _ as r -> r
      | Error `E_io | Error `E_no_space | Error (`Unexpected _) ->
          conn.connected <- false;
          Error `Disconnected)
    else Abb.Future.return (Error `Disconnected)

  let backend_msg conn len buf =
    if Pgsql_codec.Decode.buffer_length conn.decoder > conn.buf_size_threshold then
      Abb.Thread.run (fun () -> Pgsql_codec.Decode.backend_msg conn.decoder ~pos:0 ~len buf)
    else Abb.Future.return (Pgsql_codec.Decode.backend_msg conn.decoder ~pos:0 ~len buf)

  let rec wait_for_frames conn =
    let open Abb.Future.Infix_monad in
    backend_msg conn 0 conn.buf
    >>= fun ret ->
    match ret with
    | Ok [] -> (
        Abbs_io_buffered.read conn.r ~buf:conn.buf ~pos:0 ~len:(Bytes.length conn.buf)
        >>= function
        | Ok 0 | Error `E_io | Error (`Unexpected _) ->
            conn.connected <- false;
            Abb.Future.return (Error `Disconnected)
        | Ok n ->
            (* Printf.printf "Rx = %S\n%!" (Bytes.to_string (Bytes.sub conn.buf 0 n)); *)
            backend_msg conn n conn.buf >>= fun ret -> wait_for_frames' conn ret)
    | r -> wait_for_frames' conn r

  and wait_for_frames' conn = function
    | Ok [] when Pgsql_codec.Decode.needed_bytes conn.decoder = None -> wait_for_frames conn
    | Ok [] -> wait_for_frame_needed_bytes conn
    | Ok fs as r ->
        (* List.iter (fun frame -> Printf.printf "Rx %s\n%!" (Pgsql_codec.Frame.Backend.show frame)) fs; *)
        Abb.Future.return r
    | Error err -> Abb.Future.return (Error (`Parse_error err))

  and wait_for_frame_needed_bytes conn =
    (* Read all the needed bytes, this is an important performance optimization
       for large queries responses. *)
    match Pgsql_codec.Decode.needed_bytes conn.decoder with
    | Some needed_bytes -> (
        let open Abb.Future.Infix_monad in
        let b = Buffer.create needed_bytes in
        let buf = Bytes.create buf_size in
        let needed_bytes = ref needed_bytes in
        Abbs_future_combinators.retry
          ~f:(fun () ->
            let open Abbs_future_combinators.Infix_result_monad in
            Abbs_io_buffered.read conn.r ~buf ~pos:0 ~len:(Bytes.length buf)
            >>= fun n ->
            Buffer.add_subbytes b buf 0 n;
            needed_bytes := !needed_bytes - n;
            Abb.Future.return (Ok n))
          ~while_:(function
            | Ok 0 | Error _ -> false
            | Ok _ -> !needed_bytes > 0)
          ~betwixt:(fun _ -> Abbs_future_combinators.unit)
        >>= function
        | Ok 0 | Error `E_io | Error (`Unexpected _) ->
            conn.connected <- false;
            Abb.Future.return (Error `Disconnected)
        | Ok _ -> (
            let buf = Buffer.to_bytes b in
            backend_msg conn (Bytes.length buf) buf
            >>= fun ret ->
            match ret with
            | Ok [] -> wait_for_frames conn
            | Ok _ as r -> Abb.Future.return r
            | Error err -> Abb.Future.return (Error (`Parse_error err))))
    | None -> assert false

  let rec consume_until conn f =
    let open Abbs_future_combinators.Infix_result_monad in
    wait_for_frames conn
    >>= fun received_fs ->
    match CCList.drop_while (fun fr -> not (f fr)) received_fs with
    | [] -> consume_until conn f
    | fr :: fs ->
        (* Printf.printf "fr = %s\n%!" (Pgsql_codec.Frame.Backend.show fr);
         * List.iter (fun frame -> Printf.printf "Fs %s\n%!" (Pgsql_codec.Frame.Backend.show frame)) fs; *)
        Abb.Future.return (Ok fs)

  let error_response conn =
    let open Abbs_future_combinators.Infix_result_monad in
    conn.expected_frames <- [];
    consume_until conn (function
      | Pgsql_codec.Frame.Backend.ReadyForQuery { status = 'T' | 'E' } when conn.in_tx -> true
      | Pgsql_codec.Frame.Backend.ReadyForQuery { status = 'I' } when not conn.in_tx -> true
      | _ -> false)
    >>= fun res ->
    assert (res = []);
    Abb.Future.return (Ok ())

  let handle_err_frame msgs fs =
    let c = CCList.Assoc.get_exn ~eq:Char.equal 'C' msgs in
    let m = CCList.Assoc.get_exn ~eq:Char.equal 'M' msgs in
    let d = CCList.Assoc.get ~eq:Char.equal 'D' msgs in
    match c with
    | "23000"
    (* integrity_constraint_violation *)
    | "23001"
    (* restrict_violation *)
    | "23502"
    (* not_null_violation *)
    | "23503"
    (* foreign_key_violation *)
    | "23505"
    (* unique_violation *)
    | "23514"
    (* check_violation *)
    | "23P01"
    (* exclusion_violation *)
    | "40002"
    (* transaction_integrity_constraint_violation *)
    | "40001" (* serialization_failure *) -> `Integrity_err { message = m; detail = d }
    | "57014" -> `Statement_timeout
    | _ -> `Unmatching_frame fs

  let rec consume_matching ?(skip_leading_unmatched = false) conn fs =
    let open Abbs_future_combinators.Infix_result_monad in
    wait_for_frames conn
    >>= fun received_fs -> match_frames ~skip_leading_unmatched conn fs received_fs

  and match_frames ~skip_leading_unmatched conn fs received_fs =
    match (fs, received_fs) with
    | [], _ -> Abb.Future.return (Ok received_fs)
    | _, [] -> consume_matching ~skip_leading_unmatched conn fs
    | f :: fs, r_f :: r_fs when f r_f -> match_frames ~skip_leading_unmatched:false conn fs r_fs
    | _, Pgsql_codec.Frame.Backend.NoticeResponse { msgs } :: rfs ->
        conn.notice_response msgs;
        match_frames ~skip_leading_unmatched conn fs rfs
    | _, (Pgsql_codec.Frame.Backend.ErrorResponse { msgs } :: _ as r_fs) ->
        let open Abb.Future.Infix_monad in
        error_response conn >>= fun _ -> Abb.Future.return (Error (handle_err_frame msgs r_fs))
    | _, _ :: r_fs when skip_leading_unmatched -> match_frames ~skip_leading_unmatched conn fs r_fs
    | _, _ ->
        let open Abb.Future.Infix_monad in
        reset conn >>= fun _ -> Abb.Future.return (Error (`Unmatching_frame received_fs))

  and reset conn =
    let open Abbs_future_combinators.Infix_result_monad in
    send_frame conn Pgsql_codec.Frame.Frontend.Sync
    >>= fun () ->
    conn.expected_frames <- [];
    consume_matching
      ~skip_leading_unmatched:true
      conn
      Pgsql_codec.Frame.Backend.
        [
          (function
          | ReadyForQuery { status = 'T' | 'E' } when conn.in_tx -> true
          | ReadyForQuery { status = 'I' } when not conn.in_tx -> true
          | _ -> false);
        ]
    >>= fun res ->
    assert (res = []);
    Abb.Future.return (Ok ())
end

type frame_err =
  [ `Unmatching_frame of Pgsql_codec.Frame.Backend.t list
  | Io.err
  | `Disconnected
  ]
[@@deriving show]

type sql_parse_err =
  [ `Empty_variable_name
  | `Unclosed_quote of string
  | `Unknown_variable of string
  ]
[@@deriving show]

type err =
  [ `Msgs of (char * string) list
  | frame_err
  | `Disconnected
  | `Bad_result of string option list
  | `Integrity_err of integrity_err
  | `Statement_timeout
  | sql_parse_err
  ]
[@@deriving show]

module Typed_sql = struct
  module Var = struct
    module Oid = Pgsql_codec_type.Oid

    type 'a t = {
      name : string;
      oid : Pgsql_codec_type.Oid.t;
      oid_num : int;
      f : 'a -> string option list -> string option list;
    }

    type 'a v = string -> 'a t

    let make oid f name = { name; oid; f; oid_num = oid.Pgsql_codec_type.Oid.oid }
    let make_array oid f name = { name; oid; f; oid_num = oid.Pgsql_codec_type.Oid.array_oid }
    let smallint = make Oid.int2 (fun n vs -> Some (string_of_int n) :: vs)
    let integer = make Oid.int4 (fun n vs -> Some (Int32.to_string n) :: vs)
    let bigint = make Oid.int8 (fun n vs -> Some (Int64.to_string n) :: vs)
    let decimal = make Oid.numeric (fun n vs -> Some (Z.to_string n) :: vs)
    let numeric = decimal
    let real = make Oid.float4 (fun n vs -> Some (string_of_float n) :: vs)
    let double = make Oid.float8 (fun n vs -> Some (string_of_float n) :: vs)
    let smallserial = smallint
    let serial = integer
    let bigserial = bigint
    let money = make Oid.money (fun n vs -> Some (Int64.to_string n) :: vs)
    let text = make Oid.text (fun s vs -> Some s :: vs)
    let varchar = make Oid.varchar (fun s vs -> Some s :: vs)
    let char = make Oid.char (fun s vs -> Some s :: vs)
    let json = make Oid.json (fun s vs -> Some s :: vs)
    let jsonpath = make Oid.jsonpath (fun s vs -> Some s :: vs)
    let tsquery = make Oid.tsquery (fun s vs -> Some s :: vs)
    let uuid = make Oid.uuid (fun uuid vs -> Some (Uuidm.to_string uuid) :: vs)
    let boolean = make Oid.bool (fun b vs -> (if b then Some "true" else Some "false") :: vs)
    let date = make Oid.date (fun s vs -> Some s :: vs)
    let time = make Oid.time (fun s vs -> Some s :: vs)
    let timetz = make Oid.timetz (fun s vs -> Some s :: vs)
    let timestamp = make Oid.timestamp (fun s vs -> Some s :: vs)
    let timestamptz = make Oid.timestamptz (fun s vs -> Some s :: vs)
    let ud t f = make t.oid (fun v vs -> t.f (f v) vs) t.name

    let option t =
      {
        t with
        f =
          (fun o vs ->
            match o with
            | None -> None :: vs
            | Some v -> t.f v vs);
      }

    let array t =
      make_array
        t.oid
        (fun arr vs ->
          arr
          |> CCListLabels.map ~f:(fun v ->
                 match t.f v [] with
                 | [ Some v ] -> v
                 | [ None ] -> "null"
                 | _ -> assert false)
          |> CCString.concat ","
          |> fun s -> Some ("{" ^ s ^ "}") :: vs)
        t.name

    let str_array t =
      make_array
        t.oid
        (fun arr vs ->
          arr
          |> CCListLabels.map ~f:(fun v ->
                 match t.f v [] with
                 | [ Some v ] ->
                     "\""
                     ^ (v
                       |> CCString.replace ~which:`All ~sub:"\\" ~by:"\\\\"
                       |> CCString.replace ~which:`All ~sub:"\"" ~by:"\\\"")
                     ^ "\""
                 | [ None ] -> "null"
                 | _ -> assert false)
          |> CCString.concat ","
          |> fun s -> Some ("{" ^ s ^ "}") :: vs)
        t.name
  end

  module Ret = struct
    type 'a t = string option list -> ('a * string option list) option

    let take_one f = function
      | [] | None :: _ -> None
      | Some x :: xs -> CCOption.map (fun v -> (v, xs)) (f x)

    let smallint = take_one (CCOption.wrap int_of_string)
    let integer = take_one Int32.of_string_opt
    let bigint = take_one Int64.of_string_opt
    let decimal = take_one (CCOption.wrap Z.of_string)
    let numeric = decimal
    let real = take_one (CCOption.wrap float_of_string)
    let double = real
    let smallserial = take_one (CCOption.wrap int_of_string)
    let serial = take_one Int32.of_string_opt
    let bigserial = take_one Int64.of_string_opt
    let money = take_one Int64.of_string_opt
    let text = take_one CCOption.return
    let varchar = text
    let char = text
    let json = text
    let uuid = take_one Uuidm.of_string

    let boolean =
      take_one (function
        | "true" | "t" -> Some true
        | "false" | "f" -> Some false
        | _ -> None)

    let ud f xs = f xs

    let ud' f = function
      | Some s :: rest -> CCOption.map (fun v -> (v, rest)) (f s)
      | _ -> None

    let option t = function
      | None :: xs -> Some (None, xs)
      | xs -> (
          match t xs with
          | Some (v, xs) -> Some (Some v, xs)
          | None -> None)

    let debug f t v =
      f v;
      t v
  end

  type ('q, 'qr, 'p, 'pr) t =
    | Sql : ('qr, 'qr, 'pr, 'pr) t
    | Const : (('q, 'qr, 'p, 'pr) t * string) -> ('q, 'qr, 'p, 'pr) t
    | Variable : (('q, 'a -> 'qr, 'p, 'pr) t * 'a Var.t) -> ('q, 'qr, 'p, 'pr) t
    | Ret : (('q, 'qr, 'p, 'a -> 'pr) t * 'a Ret.t) -> ('q, 'qr, 'p, 'pr) t

  let sql = Sql
  let ( /^ ) t s = Const (t, s)
  let ( /% ) t v = Variable (t, v)
  let ( // ) t r = Ret (t, r)

  let rec concat : type q qr p pr qr' pr'.
      (q, qr, p, pr) t -> (qr, qr', pr, pr') t -> (q, qr', p, pr') t =
   fun t1 t2 ->
    match t2 with
    | Sql -> t1
    | Ret (t, r) -> Ret (concat t1 t, r)
    | Const (t, s) -> Const (concat t1 t, s)
    | Variable (t, v) -> Variable (concat t1 t, v)

  let ( /^^ ) t1 t2 = concat t1 t2

  let rec kbind' : type q qr p pr. (string option list -> qr) -> (q, qr, p, pr) t -> q =
   fun k t ->
    match t with
    | Sql -> k []
    | Ret (t, _) -> kbind' k t
    | Const (t, s) -> kbind' k t
    | Variable (t, v) ->
        kbind'
          (fun vs v' ->
            let ret = v.Var.f v' vs in
            k ret)
          t

  let kbind : type q qr p pr. (string option list -> qr) -> (q, qr, p, pr) t -> q =
   fun f t -> kbind' (fun vs -> f (List.rev vs)) t

  let rec extract_variables : type q qr p pr. (q, qr, p, pr) t -> string list = function
    | Sql -> []
    | Ret (t, _) -> extract_variables t
    | Variable (t, v) -> v.Var.name :: extract_variables t
    | Const (t, s) -> extract_variables t

  let rec to_query' : type q qr p pr. (q, qr, p, pr) t -> string = function
    | Sql -> ""
    | Ret (t, _) -> to_query' t
    | Variable (t, _) -> to_query' t
    | Const (t, s) ->
        let str = to_query' t in
        if str <> "" then str ^ " " ^ s else s

  let read_variable_name str idx len =
    let rec rvn' idx =
      if idx < len then
        match str.[idx] with
        | ('_' | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9') as ch -> ch :: rvn' (idx + 1)
        | _ -> []
      else []
    in
    match rvn' idx with
    | [] -> Error `Empty_variable_name
    | name -> Ok (CCString.of_list name)

  let rec replace_variables vars query buf idx len =
    if idx < len then (
      match query.[idx] with
      | ('"' | '\'') as ch ->
          Buffer.add_char buf ch;
          consume_until ch vars query buf (idx + 1) len
      | '\\' ->
          Buffer.add_char buf query.[idx + 1];
          replace_variables vars query buf (idx + 2) len
      | '$' when idx + 1 < len && query.[idx + 1] = '$' ->
          (* Variables start with $ but $$ unchanged, since it is used in
             postgresql for dollar-quoted string delims *)
          Buffer.add_string buf "$$";
          replace_variables vars query buf (idx + 2) len
      | '$' -> replace_variable_name vars query buf (idx + 1) len
      | ch ->
          Buffer.add_char buf ch;
          replace_variables vars query buf (idx + 1) len)
    else Ok (Buffer.contents buf)

  and consume_until chr vars query buf idx len =
    if idx < len then (
      match query.[idx] with
      | '\\' ->
          Buffer.add_char buf '\\';
          Buffer.add_char buf query.[idx + 1];
          consume_until chr vars query buf (idx + 2) len
      | ch when ch = chr ->
          Buffer.add_char buf ch;
          replace_variables vars query buf (idx + 1) len
      | ch ->
          Buffer.add_char buf ch;
          consume_until chr vars query buf (idx + 1) len)
    else Error (`Unclosed_quote (Buffer.contents buf))

  and replace_variable_name vars query buf idx len =
    let open CCResult.Infix in
    read_variable_name query idx len
    >>= fun name ->
    match CCArray.find_idx (CCString.equal name) vars with
    | Some (var_idx, _) ->
        Buffer.add_string buf ("$" ^ CCInt.to_string (var_idx + 1));
        replace_variables vars query buf (idx + CCString.length name) len
    | None -> Error (`Unknown_variable name)

  let to_query t =
    let query = to_query' t in
    let variables = CCArray.of_list (CCList.rev (extract_variables t)) in
    replace_variables
      variables
      query
      (Buffer.create (CCString.length query))
      0
      (CCString.length query)

  let rec to_data_type_list' : type q qr p pr. (q, qr, p, pr) t -> int32 list = function
    | Sql -> []
    | Ret (t, _) -> to_data_type_list' t
    | Variable (t, v) -> Int32.of_int v.Var.oid_num :: to_data_type_list' t
    | Const (t, s) -> to_data_type_list' t

  let to_data_type_list t = List.rev (to_data_type_list' t)
end

module Row_func = struct
  module F = struct
    type ('f, 'r) t =
      | Sql : ('r, 'r) t
      | Ret : (('f, 'a -> 'r) t * 'a Typed_sql.Ret.t) -> ('f, 'r) t

    let rec t_of_sql : type q qr f r. (q, qr, f, r) Typed_sql.t -> (f, r) t = function
      | Typed_sql.Sql -> Sql
      | Typed_sql.Ret (t, r) -> Ret (t_of_sql t, r)
      | Typed_sql.Const (t, _) -> t_of_sql t
      | Typed_sql.Variable (t, _) -> t_of_sql t

    let rec kbind' : type f r. f -> string option list -> (f, r) t -> r option =
     fun f vs t ->
      match t with
      | Sql when vs = [] -> Some f
      | Sql -> None
      | Ret (t', r) ->
          let open CCOption.Infix in
          r vs >>= fun (v, vs') -> kbind' f vs' t' >>= fun f' -> Some (f' v)

    let kbind f data t = kbind' f (List.rev data) t
  end

  type ('f, 'fr, 'acc, 'r) t = {
    func : ('f, 'fr) F.t;
    f : 'acc -> 'f;
    post_f : 'acc -> 'fr -> 'acc;
    init : 'acc;
    fin : 'acc -> 'r;
  }

  let make sql ~init ~f ~post_f ~fin =
    let func = F.t_of_sql sql in
    { func; f; init; post_f; fin }

  let ignore sql = make sql ~init:() ~f:(fun () -> ()) ~post_f:(fun () () -> ()) ~fin:(fun () -> ())
  let fold sql ~init ~f = make sql ~init ~f ~post_f:(fun _ acc -> acc) ~fin:(fun v -> v)
  let map sql ~f = make sql ~init:[] ~f:(fun _ -> f) ~post_f:(fun acc fr -> fr :: acc) ~fin:List.rev
end

module Cursor = struct
  type conn = t

  type ('p, 'pr, 'acc, 'qr) t = {
    conn : conn;
    row_func : ('p, 'pr, 'acc, 'qr) Row_func.t;
    portal : string;
  }

  let make conn row_func portal = { conn; row_func; portal }

  let rec consume_exec conn row_func st =
    let open Abbs_future_combinators.Infix_result_monad in
    Io.wait_for_frames conn >>= fun frames -> consume_exec_frames conn row_func st frames

  and consume_exec_frames conn row_func st = function
    | [] -> consume_exec conn row_func st
    | Pgsql_codec.Frame.Backend.CommandComplete _ :: fs -> consume_exec_end conn row_func st fs
    | Pgsql_codec.Frame.Backend.DataRow _ :: _ -> assert false
    | Pgsql_codec.Frame.Backend.ErrorResponse { msgs } :: _ as fs ->
        let open Abb.Future.Infix_monad in
        Io.error_response conn >>= fun _ -> Abb.Future.return (Error (Io.handle_err_frame msgs fs))
    | Pgsql_codec.Frame.Backend.NoticeResponse { msgs } :: fs ->
        conn.notice_response msgs;
        consume_exec_frames conn row_func st fs
    | fs ->
        let open Abb.Future.Infix_monad in
        Io.reset conn >>= fun _ -> Abb.Future.return (Error (`Unmatching_frame fs))

  and consume_exec_end conn row_func st = function
    | [] ->
        let open Abbs_future_combinators.Infix_result_monad in
        Io.wait_for_frames conn >>= fun frames -> consume_exec_end conn row_func st frames
    | [ Pgsql_codec.Frame.Backend.ReadyForQuery _ ] ->
        Abb.Future.return (Ok (row_func.Row_func.fin st))
    | _ -> assert false

  let execute t =
    let open Abbs_future_combinators.Infix_result_monad in
    Io.send_frame
      t.conn
      Pgsql_codec.Frame.Frontend.(Execute { portal = t.portal; max_rows = Int32.zero })
    >>= fun () ->
    Io.send_frame t.conn Pgsql_codec.Frame.Frontend.Sync
    >>= fun () ->
    Io.consume_matching t.conn (consume_expected_frames t.conn)
    >>= fun fs ->
    let st = t.row_func.Row_func.init in
    (consume_exec_frames t.conn t.row_func st fs
      : (unit, err) result Abb.Future.t
      :> (unit, [> err ]) result Abb.Future.t)

  let rec consume_fetch conn row_func st =
    let open Abbs_future_combinators.Infix_result_monad in
    Io.wait_for_frames conn >>= fun frames -> consume_fetch_frames conn row_func st frames

  and consume_fetch_frames conn row_func st = function
    | [] -> consume_fetch conn row_func st
    | Pgsql_codec.Frame.Backend.CommandComplete _ :: fs -> consume_fetch_end conn row_func st fs
    | Pgsql_codec.Frame.Backend.DataRow { data } :: fs ->
        consume_fetch_process_frame conn row_func st fs data
    | Pgsql_codec.Frame.Backend.ErrorResponse { msgs } :: _ as fs ->
        let open Abb.Future.Infix_monad in
        Io.error_response conn >>= fun _ -> Abb.Future.return (Error (Io.handle_err_frame msgs fs))
    | Pgsql_codec.Frame.Backend.NoticeResponse { msgs } :: fs ->
        conn.notice_response msgs;
        consume_fetch_frames conn row_func st fs
    | fs ->
        let open Abb.Future.Infix_monad in
        Io.reset conn >>= fun _ -> Abb.Future.return (Error (`Unmatching_frame fs))

  and consume_fetch_process_frame conn row_func st fs data =
    match Row_func.F.kbind (row_func.Row_func.f st) data row_func.Row_func.func with
    | Some fr -> consume_fetch_frames conn row_func (row_func.Row_func.post_f st fr) fs
    | None -> Abb.Future.return (Error (`Bad_result data))

  and consume_fetch_end conn row_func st = function
    | [] ->
        let open Abbs_future_combinators.Infix_result_monad in
        Io.wait_for_frames conn >>= fun frames -> consume_fetch_end conn row_func st frames
    | [ Pgsql_codec.Frame.Backend.ReadyForQuery _ ] ->
        Abb.Future.return (Ok (row_func.Row_func.fin st))
    | _ -> assert false

  let fetch ?(n = 0) t =
    let open Abbs_future_combinators.Infix_result_monad in
    Io.send_frame
      t.conn
      Pgsql_codec.Frame.Frontend.(Execute { portal = t.portal; max_rows = Int32.of_int n })
    >>= fun () ->
    Io.send_frame t.conn Pgsql_codec.Frame.Frontend.Sync
    >>= fun () ->
    Io.consume_matching t.conn (consume_expected_frames t.conn)
    >>= fun fs ->
    let st = t.row_func.Row_func.init in
    (consume_fetch_frames t.conn t.row_func st fs
      : ('a list, err) result Abb.Future.t
      :> ('a list, [> err ]) result Abb.Future.t)

  let destroy t =
    let open Abbs_future_combinators.Infix_result_monad in
    let frame = Pgsql_codec.Frame.Frontend.(Close { typ = 'P'; name = t.portal }) in
    Io.send_frame t.conn frame
    >>= fun () ->
    Io.send_frame t.conn Pgsql_codec.Frame.Frontend.Sync
    >>= fun () ->
    add_expected_frames
      t.conn
      Pgsql_codec.Frame.Backend.
        [
          equal CloseComplete;
          (function
          | ReadyForQuery _ -> true
          | _ -> false);
        ];
    Io.consume_matching t.conn (consume_expected_frames t.conn)
    >>= fun _ -> Abb.Future.return (Ok ())

  let with_cursor t ~f =
    Abbs_future_combinators.with_finally
      (fun () -> f t)
      ~finally:(fun () -> Abbs_future_combinators.ignore (destroy t))
end

module Prepared_stmt = struct
  type conn = t

  type ('q, 'qr, 'p, 'pr) t = {
    conn : conn;
    sql : ('q, 'qr, 'p, 'pr) Typed_sql.t;
    id : string;
  }

  (* Create *)
  let create conn sql =
    let open Abbs_future_combinators.Infix_result_monad in
    let stmt = gen_unique_id conn "s" in
    Abb.Future.return (Typed_sql.to_query sql)
    >>= fun query ->
    let frame =
      Pgsql_codec.Frame.Frontend.(
        Parse { stmt; query; data_types = Typed_sql.to_data_type_list sql })
    in
    Io.send_frame conn frame
    >>= fun () ->
    add_expected_frame conn Pgsql_codec.Frame.Backend.(equal ParseComplete);
    Abb.Future.return (Ok { conn; sql; id = stmt })

  let bind t rf =
    Typed_sql.kbind
      (fun vs ->
        let open Abbs_future_combinators.Infix_result_monad in
        let portal = gen_unique_id t.conn "p" in
        let bind_frame =
          Pgsql_codec.Frame.Frontend.(
            Bind { portal; stmt = t.id; format_codes = []; values = vs; result_format_codes = [] })
        in
        Io.send_frame t.conn bind_frame
        >>= fun () ->
        add_expected_frame t.conn Pgsql_codec.Frame.Backend.(equal BindComplete);
        Abb.Future.return (Ok (Cursor.make t.conn rf portal)))
      t.sql

  let destroy t =
    let open Abbs_future_combinators.Infix_result_monad in
    let frame = Pgsql_codec.Frame.Frontend.(Close { typ = 'S'; name = t.id }) in
    Io.send_frame t.conn frame
    >>= fun () ->
    Io.send_frame t.conn Pgsql_codec.Frame.Frontend.Sync
    >>= fun () ->
    add_expected_frames
      t.conn
      Pgsql_codec.Frame.Backend.
        [
          equal CloseComplete;
          (function
          | ReadyForQuery _ -> true
          | _ -> false);
        ];
    Io.consume_matching t.conn (consume_expected_frames t.conn)
    >>= fun _ -> Abb.Future.return (Ok ())

  let execute conn sql =
    Typed_sql.kbind
      (fun vs ->
        let open Abbs_future_combinators.Infix_result_monad in
        if not conn.busy then (
          conn.busy <- true;
          create conn sql
          >>= fun stmt ->
          Abbs_future_combinators.with_finally
            (fun () ->
              let portal = gen_unique_id conn "p" in
              let bind_frame =
                Pgsql_codec.Frame.Frontend.(
                  Bind
                    {
                      portal;
                      stmt = stmt.id;
                      format_codes = [];
                      values = vs;
                      result_format_codes = [];
                    })
              in
              Io.send_frame conn bind_frame
              >>= fun () ->
              add_expected_frame conn Pgsql_codec.Frame.Backend.(equal BindComplete);
              let cursor = Cursor.make conn (Row_func.ignore sql) portal in
              Cursor.execute cursor)
            ~finally:(fun () ->
              conn.busy <- false;
              Abbs_future_combinators.ignore (destroy stmt)))
        else raise (Failure "SQL connection busy"))
      sql

  let bind_execute t =
    Typed_sql.kbind
      (fun vs ->
        let open Abbs_future_combinators.Infix_result_monad in
        let portal = gen_unique_id t.conn "p" in
        let bind_frame =
          Pgsql_codec.Frame.Frontend.(
            Bind { portal; stmt = t.id; format_codes = []; values = vs; result_format_codes = [] })
        in
        Io.send_frame t.conn bind_frame
        >>= fun () ->
        add_expected_frame t.conn Pgsql_codec.Frame.Backend.(equal BindComplete);
        let cursor = Cursor.make t.conn (Row_func.ignore t.sql) portal in
        Cursor.execute cursor)
      t.sql

  let fetch conn sql ~f =
    Typed_sql.kbind
      (fun vs ->
        let open Abbs_future_combinators.Infix_result_monad in
        if not conn.busy then (
          conn.busy <- true;
          create conn sql
          >>= fun stmt ->
          Abbs_future_combinators.with_finally
            (fun () ->
              let portal = gen_unique_id conn "p" in
              let bind_frame =
                Pgsql_codec.Frame.Frontend.(
                  Bind
                    {
                      portal;
                      stmt = stmt.id;
                      format_codes = [];
                      values = vs;
                      result_format_codes = [];
                    })
              in
              Io.send_frame conn bind_frame
              >>= fun () ->
              add_expected_frame conn Pgsql_codec.Frame.Backend.(equal BindComplete);
              let cursor = Cursor.make conn (Row_func.map sql ~f) portal in
              Cursor.fetch cursor)
            ~finally:(fun () ->
              conn.busy <- false;
              Abbs_future_combinators.ignore (destroy stmt)))
        else raise (Failure "SQL connection busy"))
      sql

  let kbind :
      conn ->
      ('q, ('ret, [> err ]) result Abb.Future.t, 'p, 'pr) Typed_sql.t ->
      ('p, 'pr, 'acc, 'r) Row_func.t ->
      (('p, 'pr, 'acc, 'r) Cursor.t -> ('ret, [> err ]) result Abb.Future.t) ->
      'q =
   fun conn sql rf f ->
    Typed_sql.kbind
      (fun vs ->
        let open Abbs_future_combinators.Infix_result_monad in
        create conn sql
        >>= fun stmt ->
        Abbs_future_combinators.with_finally
          (fun () ->
            let portal = gen_unique_id conn "p" in
            let bind_frame =
              Pgsql_codec.Frame.Frontend.(
                Bind
                  {
                    portal;
                    stmt = stmt.id;
                    format_codes = [];
                    values = vs;
                    result_format_codes = [];
                  })
            in
            Io.send_frame conn bind_frame
            >>= fun () ->
            add_expected_frame conn Pgsql_codec.Frame.Backend.(equal BindComplete);
            let cursor = Cursor.make conn rf portal in
            f cursor)
          ~finally:(fun () -> Abbs_future_combinators.ignore (destroy stmt)))
      sql
end

module Auth_scram = struct
  type auth_mechanism =
    | SCRAM_SHA256
    | SCRAM_SHA256_PLUS

  type client_first = {
    channel_binding : string option;
    user : string;
    passwd : string;
    nonce : string;
    message : string;
  }

  type server_first = {
    nonce : string;
    salt : string;
    iter : int;
    message : string;
  }

  type client_final = {
    server_key : string;
    auth_message : string;
    message : string;
  }

  (* Notation and function naming come from RFC 5802, to avoid
     messing up the implementation:
        https://www.rfc-editor.org/rfc/rfc5802#section-2.2 *)
  let hmac key msg =
    let hash = Cryptokit.MAC.hmac_sha256 key in
    Cryptokit.hash_string hash msg

  let h hf msg = Cryptokit.hash_string hf msg

  let hi str salt iter =
    let ui = hmac str (salt ^ "\x00\x00\x00\x01") in
    let u = Bytes.of_string ui in
    let rec loop it ui =
      match it with
      | 0 -> String.of_bytes u
      | k ->
          let ui = hmac str ui in
          Cryptokit.xor_string ui 0 u 0 (Bytes.length u);
          loop (it - 1) ui
    in
    loop (iter - 1) ui

  (* The next functions are an implementation of
        https://www.rfc-editor.org/rfc/rfc5802#page-7 *)
  let salt_passwd passwd server_first = hi passwd server_first.salt server_first.iter

  let auth_message client_first_message_bare server_first_message client_final_message_without_proof
      =
    (* client_first_message_bare = n=$USER,r=$CLIENT_NONCE
       server_first_message = r=$NONCE,s=$SALT,i=$ITER
       client_final_message_without_proof = c=$CHANNEL_BINDING,r=$NONCE *)
    Printf.sprintf
      "%s,%s,%s"
      client_first_message_bare
      server_first_message
      client_final_message_without_proof

  let client_key salted_passwd = hmac salted_passwd "Client Key"
  let server_key salted_passwd = hmac salted_passwd "Server Key"

  let server_signature server_key auth_message =
    hmac server_key auth_message |> Base64.encode_string

  let stored_key client_key =
    let hash = Cryptokit.Hash.sha256 () in
    h hash client_key

  let client_proof client_key client_signature =
    let result = Bytes.of_string client_signature in
    Cryptokit.xor_string client_key 0 result 0 (Bytes.length result);
    result |> String.of_bytes |> Base64.encode_string

  (* SCRAM Steps

     Check RFCs 5802 or 7677 to get a better idea on each 
     exchange format.

     https://www.rfc-editor.org/rfc/rfc5802#section-5
     https://www.rfc-editor.org/rfc/rfc7677.html#section-3 *)
  let client_first auth_mechanism user passwd =
    let nonce_len = 16 in
    let random_data = CCString.init nonce_len (fun _ -> Char.chr @@ Random.int 256) in
    let nonce = Base64.encode_string random_data in
    let channel_binding =
      match auth_mechanism with
      | SCRAM_SHA256 -> None
      | SCRAM_SHA256_PLUS -> Some "p=tls-server-end-point"
    in
    let prefix = CCOption.value channel_binding ~default:"n" in
    let message = Printf.sprintf "%s,,n=%s,r=%s" prefix user nonce in
    let client_request = { channel_binding; nonce; user; passwd; message } in
    (client_request, message)

  let parse_server_reply message =
    (* The first server response looks like this:
        |----------nonce-----------|
      r=<client_nonce><server_nonce>,s=<salt>,i=<iter> *)
    let fields = CCString.split ~by:"," message in
    let prefixes = [ "r="; "s="; "i=" ] in
    let remove_prefix prefix item =
      if CCString.prefix ~pre:prefix item then Some (CCString.drop (String.length prefix) item)
      else None
    in
    let extract prefixes fields =
      match List.map2 remove_prefix prefixes fields with
      | [ Some n; Some s; Some i ] ->
          let salt = Base64.decode_exn s in
          let iter = int_of_string i in
          Some (n, salt, iter)
      | _ -> None
    in
    match extract prefixes fields with
    | Some (nonce, salt, iter) -> Some { nonce; salt; iter; message }
    | _ -> None

  let client_final client_first server_first =
    let salted_password = salt_passwd client_first.passwd server_first in
    let client_first_message_bare =
      Printf.sprintf "n=%s,r=%s" client_first.user client_first.nonce
    in
    let client_final_without_proof = Printf.sprintf "c=biws,r=%s" server_first.nonce in
    let auth_message =
      auth_message client_first_message_bare server_first.message client_final_without_proof
    in
    let client_key = client_key salted_password in
    let server_key = server_key salted_password in
    let stored_key = stored_key client_key in
    let client_signature = hmac stored_key auth_message in
    let proof = client_proof client_key client_signature in
    let message = Printf.sprintf "%s,p=%s" client_final_without_proof proof in
    let record = { server_key; auth_message; message } in
    (record, message)

  let verify_server_final client_final server_final =
    let is_verifier = CCString.chop_prefix ~pre:"v=" server_final in
    let is_error = CCString.chop_prefix ~pre:"e=" server_final in
    match (is_verifier, is_error) with
    | Some signature_from_server, _ ->
        let signature_from_client =
          server_signature client_final.server_key client_final.auth_message
        in
        (* If both match then it's proof that the server has access to the
           client's key *)
        if signature_from_client = signature_from_server then Ok ()
        else Error "Invalid server signature"
    | _, Some error_reason -> Error error_reason
    | _ -> Error "Unsuported final server message format for AuthenticationSASLFinal"
end

type create_err =
  [ `Unexpected of (exn[@printer fun fmt v -> fprintf fmt "%s" (Printexc.to_string v)])
  | `Connection_failed
  | `Connect_missing_password_err
  | `Tls_negotiate_err of Abb_tls.err
  | `Tls_required_but_denied_err
  | `Tls_unexpected_response of int * string
  | `Unsupported_auth_gss_err
  | `Unsupported_auth_sasl_err
  | `Unsupported_auth_scm_credential_err
  | `Unsupported_auth_sspi_err
  | frame_err
  ]
[@@deriving show]

let rec create_sm
    ?tls_config
    ?passwd
    ~notice_response
    ~buf_size_threshold
    ~host
    ~port
    ~user
    database =
  let open Abbs_future_combinators.Infix_result_monad in
  Abbs_happy_eyeballs.connect host [ port ]
  >>= fun (_, tcp) ->
  match tls_config with
  | None ->
      let r, w = Abbs_io_buffered.Of.of_tcp_socket ~size:buf_size tcp in
      create_sm_perform_login r w ?passwd ~notice_response ~buf_size_threshold ~user database
  | Some (`Require tls_config) ->
      create_sm_ssl_conn
        ?passwd
        ~buf_size_threshold
        ~required:true
        ~notice_response
        ~host
        ~port
        ~user
        tls_config
        tcp
        database
  | Some (`Prefer tls_config) ->
      create_sm_ssl_conn
        ?passwd
        ~buf_size_threshold
        ~required:false
        ~notice_response
        ~host
        ~port
        ~user
        tls_config
        tcp
        database

and create_sm_ssl_conn
    ?passwd
    ~buf_size_threshold
    ~required
    ~notice_response
    ~host
    ~port
    ~user
    tls_config
    tcp
    database =
  let open Abbs_future_combinators.Infix_result_monad in
  let buf = Buffer.create 5 in
  let bytes = Io.encode_frame buf Pgsql_codec.Frame.Frontend.SSLRequest in
  let r, w = Abbs_io_buffered.Of.of_tcp_socket ~size:buf_size tcp in
  Abbs_io_buffered.write w ~bufs:[ Io.write_buf bytes ]
  >>= fun _ ->
  Abbs_io_buffered.flushed w
  >>= fun () ->
  let bytes = Bytes.create 5 in
  Abbs_io_buffered.read r ~buf:bytes ~pos:0 ~len:(Bytes.length bytes)
  >>= function
  | n when n = 1 && Bytes.get bytes 0 = 'S' -> (
      match Abbs_tls.client_tcp ~size:buf_size tcp tls_config host with
      | Ok (r, w) ->
          create_sm_perform_login r w ?passwd ~notice_response ~buf_size_threshold ~user database
      | Error (#Abb_tls.err as err) -> Abb.Future.return (Error (`Tls_negotiate_err err)))
  | n when n = 1 && Bytes.get bytes 0 = 'N' && not required ->
      create_sm_perform_login r w ?passwd ~notice_response ~buf_size_threshold ~user database
  | n when n = 1 && Bytes.get bytes 0 = 'N' && required ->
      Abb.Future.return (Error `Tls_required_but_denied_err)
  | n -> Abb.Future.return (Error (`Tls_unexpected_response (n, Bytes.sub_string bytes 0 n)))

and create_sm_perform_login r w ?passwd ~notice_response ~buf_size_threshold ~user database =
  let open Abbs_future_combinators.Infix_result_monad in
  let decoder = Pgsql_codec.Decode.create () in
  let buf = Bytes.create buf_size in
  let scratch = Buffer.create buf_size in
  let t =
    {
      connected = true;
      decoder;
      buf;
      scratch;
      r;
      w;
      backend_key_data = Backend_key_data.{ pid = Int32.zero; secret_key = Int32.zero };
      unique_id = 0;
      notice_response;
      expected_frames = [];
      in_tx = false;
      busy = false;
      buf_size_threshold;
    }
  in
  let msgs = [ ("user", user); ("database", database) ] in
  let startup = Pgsql_codec.Frame.Frontend.(StartupMessage { msgs }) in
  Io.send_frame t startup >>= fun () -> create_sm_login ?passwd ~user t

and create_sm_login ?passwd ~user t =
  let open Abbs_future_combinators.Infix_result_monad in
  Io.wait_for_frames t >>= fun frames -> create_sm_process_login_frames ?passwd ~user t frames

(* TODO: Maybe it's worth aglutinating step_02 and step_03
   under the same recursive function, left it for a future
   refactor *)
and create_sm_scram_sha256_step_03 ?passwd ~user client_final t =
  let module B = Pgsql_codec.Frame.Backend in
  let open Abbs_future_combinators.Infix_result_monad in
  Io.wait_for_frames t
  >>= function
  | B.AuthenticationSASLFinal { data } :: fs -> (
      match Auth_scram.verify_server_final client_final data with
      | Ok _ ->
          (* Should be waiting for the next frame as an AuthenticationOk *)
          create_sm_process_login_frames ?passwd ~user t fs
      | _ -> Abb.Future.return (Error `Unsupported_auth_sasl_err))
  | fs -> Abb.Future.return (Error (`Unmatching_frame fs))

and create_sm_scram_sha256_step_02 ?passwd ~user client_request t =
  let module B = Pgsql_codec.Frame.Backend in
  let open Abbs_future_combinators.Infix_result_monad in
  Io.wait_for_frames t
  >>= function
  | B.AuthenticationSASLContinue { data } :: fs -> (
      match Auth_scram.parse_server_reply data with
      | Some server_response ->
          let client_final, data = Auth_scram.client_final client_request server_response in
          Io.send_frame t Pgsql_codec.Frame.Frontend.(SASLResponse { data })
          >>= fun () -> create_sm_scram_sha256_step_03 ?passwd ~user client_final t
      | _ -> Abb.Future.return (Error `Unsupported_auth_sasl_err))
  | fs -> Abb.Future.return (Error (`Unmatching_frame fs))

and create_sm_process_login_frames ?passwd ~user t =
  let open Pgsql_codec.Frame.Backend in
  function
  | [] -> create_sm_login ?passwd ~user t
  | AuthenticationOk :: fs -> create_sm_process_login_frames ?passwd ~user t fs
  | AuthenticationCleartextPassword :: fs -> (
      let open Abbs_future_combinators.Infix_result_monad in
      match passwd with
      | Some password ->
          Io.send_frame t Pgsql_codec.Frame.Frontend.(PasswordMessage { password })
          >>= fun () -> create_sm_process_login_frames ?passwd ~user t fs
      | None -> Abb.Future.return (Error `Connect_missing_password_err))
  | AuthenticationMD5Password { salt } :: fs -> (
      let open Abbs_future_combinators.Infix_result_monad in
      match passwd with
      | Some password ->
          let passuser = Digest.to_hex (Digest.string (password ^ user)) in
          let passusersalt = Digest.to_hex (Digest.string (passuser ^ salt)) in
          let password = "md5" ^ passusersalt in
          Io.send_frame t Pgsql_codec.Frame.Frontend.(PasswordMessage { password })
          >>= fun () -> create_sm_process_login_frames ?passwd ~user t fs
      | None -> Abb.Future.return (Error `Connect_missing_password_err))
  | ParameterStatus _ :: fs -> create_sm_process_login_frames ?passwd ~user t fs
  | BackendKeyData { pid; secret_key } :: fs ->
      let t = { t with backend_key_data = Backend_key_data.{ pid; secret_key } } in
      create_sm_process_login_frames ?passwd ~user t fs
  | [ ReadyForQuery _ ] -> Abb.Future.return (Ok t)
  | AuthenticationSCMCredential :: _ ->
      Abb.Future.return (Error `Unsupported_auth_scm_credential_err)
  | AuthenticationGSS :: _ -> Abb.Future.return (Error `Unsupported_auth_gss_err)
  | AuthenticationSASL { auth_mechanisms } :: fs
    when CCList.mem ~eq:CCString.equal "SCRAM-SHA-256" auth_mechanisms -> (
      match passwd with
      | Some password ->
          let open Abbs_future_combinators.Infix_result_monad in
          let client_first, data = Auth_scram.client_first Auth_scram.SCRAM_SHA256 user password in
          let auth_mechanism = "SCRAM-SHA-256" in
          Io.send_frame t Pgsql_codec.Frame.Frontend.(SASLInitialResponse { auth_mechanism; data })
          >>= fun () -> create_sm_scram_sha256_step_02 ?passwd ~user client_first t
      | None -> Abb.Future.return (Error `Connect_missing_password_err))
  | AuthenticationSASL { auth_mechanisms } :: _ ->
      Abb.Future.return (Error `Unsupported_auth_sasl_err)
  | AuthenticationSSPI :: _ -> Abb.Future.return (Error `Unsupported_auth_sspi_err)
  | fs -> Abb.Future.return (Error (`Unmatching_frame fs))

let create
    ?tls_config
    ?passwd
    ?(port = 5432)
    ?(notice_response = fun _ -> ())
    ?(buf_size_threshold = buf_size_threshold)
    ~host
    ~user
    database =
  let open Abb.Future.Infix_monad in
  assert (buf_size_threshold > 0);
  create_sm ?tls_config ?passwd ~notice_response ~buf_size_threshold ~host ~port ~user database
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error `Disconnected | Error #Abb_happy_eyeballs.connect_err | Error `E_io | Error `E_no_space ->
      Abb.Future.return (Error `Connection_failed)
  | ( Error `Connect_missing_password_err
    | Error (`Tls_negotiate_err _)
    | Error `Tls_required_but_denied_err
    | Error (`Tls_unexpected_response _)
    | Error (`Unmatching_frame _)
    | Error `Unsupported_auth_gss_err
    | Error `Unsupported_auth_sasl_err
    | Error `Unsupported_auth_scm_credential_err
    | Error `Unsupported_auth_sspi_err
    | Error (`Unexpected _)
    | Error (`Parse_error _) ) as err -> Abb.Future.return err

let destroy t =
  (* Destroy is idempotent *)
  if t.connected then (
    t.connected <- false;
    Abbs_future_combinators.ignore (Abbs_io_buffered.close_writer t.w))
  else Abb.Future.return ()

let connected t = t.connected

let ping t =
  if t.connected then (
    let open Abb.Future.Infix_monad in
    Io.reset t
    >>= function
    | Ok () -> Abb.Future.return true
    | Error _ ->
        (* Reset didn't work?  End this connection.  There are just too many
           possible reasons it could have failed. *)
        t.connected <- false;
        Abb.Future.return false)
  else Abb.Future.return false

let tx_commit t =
  let open Abbs_future_combinators.Infix_result_monad in
  Io.send_frame t Pgsql_codec.Frame.Frontend.(Query { query = "COMMIT" })
  >>= fun () ->
  t.in_tx <- false;
  add_expected_frames
    t
    Pgsql_codec.Frame.Backend.
      [ equal (CommandComplete { tag = "COMMIT" }); equal (ReadyForQuery { status = 'I' }) ];
  Io.consume_matching t (consume_expected_frames t)

let tx_rollback t =
  let open Abbs_future_combinators.Infix_result_monad in
  Io.reset t
  >>= fun () ->
  t.in_tx <- false;
  Io.send_frame t Pgsql_codec.Frame.Frontend.(Query { query = "ROLLBACK" })
  >>= fun () ->
  Io.consume_matching
    ~skip_leading_unmatched:true
    t
    Pgsql_codec.Frame.Backend.
      [ equal (CommandComplete { tag = "ROLLBACK" }); equal (ReadyForQuery { status = 'I' }) ]

let tx t ~f =
  if t.in_tx then raise Nested_tx_not_supported;
  Abbs_future_combinators.on_failure
    (fun () ->
      let open Abb.Future.Infix_monad in
      t.in_tx <- true;
      Io.send_frame t Pgsql_codec.Frame.Frontend.(Query { query = "BEGIN" })
      >>= fun _ ->
      Io.consume_matching
        ~skip_leading_unmatched:true
        t
        Pgsql_codec.Frame.Backend.
          [ equal (CommandComplete { tag = "BEGIN" }); equal (ReadyForQuery { status = 'T' }) ]
      >>= function
      | Ok [] -> (
          f ()
          >>= function
          | Ok _ as r ->
              let open Abbs_future_combinators.Infix_result_monad in
              tx_commit t >>= fun _ -> Abb.Future.return r
          | Error _ as r -> tx_rollback t >>= fun _ -> Abb.Future.return r)
      | Ok fs -> tx_rollback t >>= fun _ -> Abb.Future.return (Error (`Unmatching_frame fs))
      | Error _ as err -> tx_rollback t >>= fun _ -> Abb.Future.return err)
    ~failure:(fun () -> Abbs_future_combinators.ignore (tx_rollback t))

let clean_string s =
  s
  |> CCString.split_on_char '\n'
  |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
  |> CCString.concat "\n"
