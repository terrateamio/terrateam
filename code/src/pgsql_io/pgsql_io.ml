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

module Io = struct
  type err = [ `Parse_error of Pgsql_codec.Decode.err ] [@@deriving show, eq]

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
          Error `Disconnected
    ) else
      Abb.Future.return (Error `Disconnected)

  let rec wait_for_frames conn =
    let open Abb.Future.Infix_monad in
    match Pgsql_codec.Decode.backend_msg conn.decoder ~pos:0 ~len:0 conn.buf with
      | Ok [] -> (
          Abbs_io_buffered.read conn.r ~buf:conn.buf ~pos:0 ~len:(Bytes.length conn.buf)
          >>= function
          | Ok 0 | Error `E_io | Error (`Unexpected _) ->
              conn.connected <- false;
              Abb.Future.return (Error `Disconnected)
          | Ok n ->
              (* Printf.printf "Rx = %S\n%!" (Bytes.to_string (Bytes.sub conn.buf 0 n)); *)
              wait_for_frames'
                conn
                (Pgsql_codec.Decode.backend_msg conn.decoder ~pos:0 ~len:n conn.buf) )
      | r     -> wait_for_frames' conn r

  and wait_for_frames' conn = function
    | Ok []      -> wait_for_frames conn
    | Ok fs as r ->
        (* List.iter (fun frame -> Printf.printf "Rx %s\n%!" (Pgsql_codec.Frame.Backend.show frame)) fs; *)
        Abb.Future.return r
    | Error err  -> Abb.Future.return (Error (`Parse_error err))

  let rec consume_until conn f =
    let open Abbs_future_combinators.Infix_result_monad in
    wait_for_frames conn
    >>= fun received_fs ->
    match CCList.drop_while (fun fr -> not (f fr)) received_fs with
      | []       -> consume_until conn f
      | fr :: fs ->
          (* Printf.printf "fr = %s\n%!" (Pgsql_codec.Frame.Backend.show fr);
           * List.iter
           *   (fun frame -> Printf.printf "Fs %s\n%!" (Pgsql_codec.Frame.Backend.show frame))
           *   fs; *)
          Abb.Future.return (Ok fs)

  let reset conn =
    let open Abbs_future_combinators.Infix_result_monad in
    (* send_frame conn Pgsql_codec.Frame.Frontend.Sync
     * >>= fun () -> *)
    conn.expected_frames <- [];
    consume_until conn (function
        | Pgsql_codec.Frame.Backend.ReadyForQuery { status = 'I' } -> true
        | _ -> false)
    >>= fun res ->
    assert (res = []);
    Abb.Future.return (Ok ())

  let rec consume_matching conn fs =
    let open Abbs_future_combinators.Infix_result_monad in
    wait_for_frames conn >>= fun received_fs -> match_frames conn fs received_fs

  and match_frames conn fs received_fs =
    match (fs, received_fs) with
      | ([], _) -> Abb.Future.return (Ok received_fs)
      | (_, []) -> consume_matching conn fs
      | (f :: fs, r_f :: r_fs) when f r_f -> match_frames conn fs r_fs
      | (_, _) -> Abb.Future.return (Error (`Unmatching_frame received_fs))
end

type frame_err =
  [ `Unmatching_frame of Pgsql_codec.Frame.Backend.t list
  | Io.err
  | `Disconnected
  ]
[@@deriving show]

type err =
  [ `Msgs of (char * string) list
  | frame_err
  | `Disconnected
  | `Bad_result of string option list
  ]
[@@deriving show]

module Typed_sql = struct
  module Var = struct
    module Oid = Pgsql_codec_type.Oid

    type 'a t = {
      oid : Pgsql_codec_type.Oid.t;
      oid_num : int;
      f : 'a -> string option list -> string option list;
    }

    let make oid f = { oid; f; oid_num = oid.Pgsql_codec_type.Oid.oid }

    let make_array oid f = { oid; f; oid_num = oid.Pgsql_codec_type.Oid.array_oid }

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

    let tsquery = make Oid.tsquery (fun s vs -> Some s :: vs)

    let uuid = make Oid.uuid (fun uuid vs -> Some (Uuidm.to_string uuid) :: vs)

    let boolean =
      make Oid.bool (fun b vs ->
          ( if b then
            Some "true"
          else
            Some "false" )
          :: vs)

    let timestamp = make Oid.timestamp (fun s vs -> Some s :: vs)

    let timestamptz = make Oid.timestamptz (fun s vs -> Some s :: vs)

    let ud t f = make t.oid (fun v vs -> t.f (f v) vs)

    let option t =
      make t.oid (fun o vs ->
          match o with
            | None   -> None :: vs
            | Some v -> t.f v vs)

    let array t =
      make_array t.oid (fun arr vs ->
          arr
          |> CCListLabels.map ~f:(fun v ->
                 match t.f v [] with
                   | [ Some v ] -> v
                   | [ None ]   -> "null"
                   | _          -> assert false)
          |> CCString.concat ","
          |> fun s -> Some ("{" ^ s ^ "}") :: vs)

    let str_array t =
      make_array t.oid (fun arr vs ->
          arr
          |> CCListLabels.map ~f:(fun v ->
                 match t.f v [] with
                   | [ Some v ] ->
                       "\""
                       ^ ( v
                         |> CCString.replace ~which:`All ~sub:"\\" ~by:"\\\\"
                         |> CCString.replace ~which:`All ~sub:"\"" ~by:"\\\"" )
                       ^ "\""
                   | [ None ]   -> "null"
                   | _          -> assert false)
          |> CCString.concat ","
          |> fun s -> Some ("{" ^ s ^ "}") :: vs)
  end

  module Ret = struct
    type 'a t = string option list -> ('a * string option list) option

    let take_one f = function
      | [] | None :: _ -> None
      | Some x :: xs   -> CCOpt.map (fun v -> (v, xs)) (f x)

    let smallint = take_one (CCOpt.wrap int_of_string)

    let integer = take_one Int32.of_string_opt

    let bigint = take_one Int64.of_string_opt

    let decimal = take_one (CCOpt.wrap Z.of_string)

    let numeric = decimal

    let real = take_one (CCOpt.wrap float_of_string)

    let double = real

    let smallserial = take_one (CCOpt.wrap int_of_string)

    let serial = take_one Int32.of_string_opt

    let bigserial = take_one Int64.of_string_opt

    let money = take_one Int64.of_string_opt

    let text = take_one CCOpt.return

    let varchar = text

    let char = text

    let uuid = take_one Uuidm.of_string

    let boolean =
      take_one (function
          | "true"  -> Some true
          | "false" -> Some false
          | _       -> None)

    let ud f xs = f xs

    let option t = function
      | None :: xs -> Some (None, xs)
      | xs         -> (
          match t xs with
            | Some (v, xs) -> Some (Some v, xs)
            | None         -> None )
  end

  type ('q, 'qr, 'p, 'pr) t =
    | Sql : ('qr, 'qr, 'pr, 'pr) t
    | Const    : (('q, 'qr, 'p, 'pr) t * string) -> ('q, 'qr, 'p, 'pr) t
    | Variable : (('q, 'a -> 'qr, 'p, 'pr) t * 'a Var.t) -> ('q, 'qr, 'p, 'pr) t
    | Ret      : (('q, 'qr, 'p, 'a -> 'pr) t * 'a Ret.t) -> ('q, 'qr, 'p, 'pr) t

  let sql = Sql

  let ( /^ ) t s = Const (t, s)

  let ( /% ) t v = Variable (t, v)

  let ( // ) t r = Ret (t, r)

  let rec kbind' : type q qr p pr. (string option list -> qr) -> (q, qr, p, pr) t -> q =
   fun k t ->
    match t with
      | Sql             -> k []
      | Ret (t, _)      -> kbind' k t
      | Const (t, s)    -> kbind' k t
      | Variable (t, v) ->
          kbind'
            (fun vs v' ->
              let ret = v.Var.f v' vs in
              k ret)
            t

  let kbind : type q qr p pr. (string option list -> qr) -> (q, qr, p, pr) t -> q =
   fun f t -> kbind' (fun vs -> f (List.rev vs)) t

  let rec to_query : type q qr p pr. (q, qr, p, pr) t -> string = function
    | Sql             -> ""
    | Ret (t, _)      -> to_query t
    | Variable (t, _) -> to_query t
    | Const (t, s)    ->
        let str = to_query t in
        if str <> "" then
          str ^ " " ^ s
        else
          s

  let rec to_data_type_list' : type q qr p pr. (q, qr, p, pr) t -> int32 list = function
    | Sql             -> []
    | Ret (t, _)      -> to_data_type_list' t
    | Variable (t, v) -> Int32.of_int v.Var.oid_num :: to_data_type_list' t
    | Const (t, s)    -> to_data_type_list' t

  let to_data_type_list t = List.rev (to_data_type_list' t)
end

module Row_func = struct
  module F = struct
    type ('f, 'r) t =
      | Sql : ('r, 'r) t
      | Ret : (('f, 'a -> 'r) t * 'a Typed_sql.Ret.t) -> ('f, 'r) t

    let rec t_of_sql : type q qr f r. (q, qr, f, r) Typed_sql.t -> (f, r) t = function
      | Typed_sql.Sql             -> Sql
      | Typed_sql.Ret (t, r)      -> Ret (t_of_sql t, r)
      | Typed_sql.Const (t, _)    -> t_of_sql t
      | Typed_sql.Variable (t, _) -> t_of_sql t

    let rec kbind' : type f r. f -> string option list -> (f, r) t -> r option =
     fun f vs t ->
      match t with
        | Sql when vs = [] -> Some f
        | Sql -> None
        | Ret (t', r) ->
            let open CCOpt.Infix in
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
    | Pgsql_codec.Frame.Backend.NoticeResponse { msgs } :: fs ->
        conn.notice_response msgs;
        consume_exec_frames conn row_func st fs
    | Pgsql_codec.Frame.Backend.CommandComplete _ :: fs -> consume_exec_end conn row_func st fs
    | Pgsql_codec.Frame.Backend.DataRow _ :: _ -> assert false
    | fs -> Abb.Future.return (Error (`Unmatching_frame fs))

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
    ( consume_exec_frames t.conn t.row_func st fs
      : (unit, err) result Abb.Future.t
      :> (unit, [> err ]) result Abb.Future.t )

  let rec consume_fetch conn row_func st =
    let open Abbs_future_combinators.Infix_result_monad in
    Io.wait_for_frames conn >>= fun frames -> consume_fetch_frames conn row_func st frames

  and consume_fetch_frames conn row_func st = function
    | [] -> consume_fetch conn row_func st
    | Pgsql_codec.Frame.Backend.CommandComplete _ :: fs -> consume_fetch_end conn row_func st fs
    | Pgsql_codec.Frame.Backend.DataRow { data } :: fs ->
        consume_fetch_process_frame conn row_func st fs data
    | fs -> Abb.Future.return (Error (`Unmatching_frame fs))

  and consume_fetch_process_frame conn row_func st fs data =
    match Row_func.F.kbind (row_func.Row_func.f st) data row_func.Row_func.func with
      | Some fr -> consume_fetch_frames conn row_func (row_func.Row_func.post_f st fr) fs
      | None    -> Abb.Future.return (Error (`Bad_result data))

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
    ( consume_fetch_frames t.conn t.row_func st fs
      : ('a list, err) result Abb.Future.t
      :> ('a list, [> err ]) result Abb.Future.t )

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
          | _               -> false);
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
    let query = Typed_sql.to_query sql in
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
          | _               -> false);
        ];
    Io.consume_matching t.conn (consume_expected_frames t.conn)
    >>= fun _ -> Abb.Future.return (Ok ())

  let execute conn sql =
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
            let cursor = Cursor.make conn (Row_func.ignore sql) portal in
            Cursor.execute cursor)
          ~finally:(fun () -> Abbs_future_combinators.ignore (destroy stmt)))
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
          ~finally:(fun () -> Abbs_future_combinators.ignore (destroy stmt)))
      sql
end

type create_err =
  [ `Unexpected of (exn[@opaque] [@equal ( = )])
  | `Connection_failed
  | Io.err
  ]
[@@deriving show, eq]

let rec create_sm ?tls_config ?passwd ~host ~port ~user database tcp =
  let open Abbs_future_combinators.Infix_result_monad in
  Abb.Socket.getaddrinfo
    ~hints:
      Abb_intf.Socket.
        [ Addrinfo_hints.Socket_type Socket_type.Stream; Addrinfo_hints.Family Domain.Inet4 ]
    Abb_intf.Socket.Addrinfo_query.(Host_service (host, string_of_int port))
  >>= function
  | []     -> Abb.Future.return (Error `Connection_failed)
  | r :: _ -> (
      let addr = r.Abb_intf.Socket.Addrinfo.addr in
      Abb.Socket.Tcp.connect tcp addr
      >>= fun () ->
      match tls_config with
        | None                       ->
            let (r, w) = Abbs_io_buffered.Of.of_tcp_socket ~size:4096 tcp in
            create_sm_perform_login r w ?passwd ~user database
        | Some (`Require tls_config) ->
            create_sm_ssl_conn ?passwd ~required:true ~host ~port ~user tls_config tcp database
        | Some (`Prefer tls_config)  ->
            create_sm_ssl_conn ?passwd ~required:false ~host ~port ~user tls_config tcp database )

and create_sm_ssl_conn ?passwd ~required ~host ~port ~user tls_config tcp database =
  let open Abbs_future_combinators.Infix_result_monad in
  let buf = Buffer.create 5 in
  let bytes = Io.encode_frame buf Pgsql_codec.Frame.Frontend.SSLRequest in
  let (r, w) = Abbs_io_buffered.Of.of_tcp_socket ~size:4096 tcp in
  Abbs_io_buffered.write w ~bufs:[ Io.write_buf bytes ]
  >>= fun _ ->
  Abbs_io_buffered.flushed w
  >>= fun () ->
  let bytes = Bytes.create 5 in
  Abbs_io_buffered.read r ~buf:bytes ~pos:0 ~len:(Bytes.length bytes)
  >>= function
  | n when n = 1 && Bytes.get bytes 0 = 'S' -> (
      match Abbs_tls.client_tcp tcp tls_config host with
        | Ok (r, w) -> create_sm_perform_login r w ?passwd ~user database
        | Error _   -> failwith "nyi" )
  | n when n = 1 && Bytes.get bytes 0 = 'N' && not required -> failwith "nyi"
  | n when n = 1 && Bytes.get bytes 0 = 'N' && required -> failwith "nyi"
  | _ -> failwith "nyi"

and create_sm_perform_login r w ?passwd ~user database =
  let open Abbs_future_combinators.Infix_result_monad in
  let decoder = Pgsql_codec.Decode.create () in
  let buf = Bytes.create 4096 in
  let scratch = Buffer.create 4096 in
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
      notice_response = (fun _ -> ());
      expected_frames = [];
    }
  in
  let msgs = [ ("user", user); ("database", database) ] in
  let startup = Pgsql_codec.Frame.Frontend.(StartupMessage { msgs }) in
  Io.send_frame t startup >>= fun () -> create_sm_login ?passwd ~user t

and create_sm_login ?passwd ~user t =
  let open Abbs_future_combinators.Infix_result_monad in
  Io.wait_for_frames t >>= fun frames -> create_sm_process_login_frames ?passwd ~user t frames

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
        | None          -> failwith "nyi" )
  | AuthenticationMD5Password { salt } :: fs -> (
      let open Abbs_future_combinators.Infix_result_monad in
      match passwd with
        | Some password ->
            let passuser = Digest.to_hex (Digest.string (password ^ user)) in
            let passusersalt = Digest.to_hex (Digest.string (passuser ^ salt)) in
            let password = "md5" ^ passusersalt in
            Io.send_frame t Pgsql_codec.Frame.Frontend.(PasswordMessage { password })
            >>= fun () -> create_sm_process_login_frames ?passwd ~user t fs
        | None          -> failwith "nyi" )
  | ParameterStatus _ :: fs -> create_sm_process_login_frames ?passwd ~user t fs
  | BackendKeyData { pid; secret_key } :: fs ->
      let t = { t with backend_key_data = Backend_key_data.{ pid; secret_key } } in
      create_sm_process_login_frames ?passwd ~user t fs
  | [ ReadyForQuery _ ] -> Abb.Future.return (Ok t)
  | _ -> failwith "nyi"

let create ?tls_config ?passwd ?(port = 5432) ~host ~user database =
  let open Abb.Future.Infix_monad in
  let tcp = CCResult.get_exn (Abb.Socket.Tcp.create ~domain:Abb_intf.Socket.Domain.Inet4) in
  Abbs_future_combinators.on_failure
    (fun () ->
      create_sm ?tls_config ?passwd ~host ~port ~user database tcp
      >>= function
      | Ok _ as r -> Abb.Future.return r
      | Error `Disconnected
      | Error `E_io
      | Error `E_no_space
      | Error `Connection_failed
      | Error `E_access
      | Error `E_address_family_not_supported
      | Error `E_address_in_use
      | Error `E_address_not_available
      | Error `E_bad_file
      | Error `E_connection_refused
      | Error `E_connection_reset
      | Error `E_host_unreachable
      | Error `E_invalid
      | Error `E_is_connected
      | Error `E_network_unreachable ->
          Abbs_future_combinators.ignore (Abb.Socket.close tcp)
          >>= fun () -> Abb.Future.return (Error `Connection_failed)
      | (Error (`Unexpected _) | Error (`Parse_error _)) as err ->
          Abbs_future_combinators.ignore (Abb.Socket.close tcp) >>= fun () -> Abb.Future.return err)
    ~failure:(fun () -> Abbs_future_combinators.ignore (Abb.Socket.close tcp))

let destroy t =
  t.connected <- false;
  Abbs_future_combinators.ignore (Abbs_io_buffered.close_writer t.w)

let connected t = t.connected

let tx_commit t =
  let open Abbs_future_combinators.Infix_result_monad in
  Io.send_frame t Pgsql_codec.Frame.Frontend.(Query { query = "COMMIT" })
  >>= fun () ->
  add_expected_frames
    t
    Pgsql_codec.Frame.Backend.
      [ equal (CommandComplete { tag = "COMMIT" }); equal (ReadyForQuery { status = 'I' }) ];
  Io.consume_matching t (consume_expected_frames t)

let tx_rollback t =
  let open Abbs_future_combinators.Infix_result_monad in
  Io.send_frame t Pgsql_codec.Frame.Frontend.(Query { query = "ROLLBACK" })
  >>= fun () ->
  (* add_expected_frames
   *   t
   *   Pgsql_codec.Frame.Backend.
   *     [ equal (CommandComplete { tag = "ROLLBACK" }); equal (ReadyForQuery { status = 'I' }) ];
   * Io.consume_matching t (consume_expected_frames t) *)
  Io.reset t

let tx t ~f =
  Abbs_future_combinators.on_failure
    (fun () ->
      let open Abb.Future.Infix_monad in
      Io.send_frame t Pgsql_codec.Frame.Frontend.(Query { query = "BEGIN" })
      >>= fun _ ->
      add_expected_frames
        t
        Pgsql_codec.Frame.Backend.
          [ equal (CommandComplete { tag = "BEGIN" }); equal (ReadyForQuery { status = 'T' }) ];
      f ()
      >>= function
      | Ok _ as r    ->
          let open Abbs_future_combinators.Infix_result_monad in
          tx_commit t >>= fun _ -> Abb.Future.return r
      | Error _ as r -> tx_rollback t >>= fun _ -> Abb.Future.return r)
    ~failure:(fun () -> Abbs_future_combinators.ignore (tx_rollback t))
