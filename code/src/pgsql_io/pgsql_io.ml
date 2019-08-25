module Backend_key_data = struct
  type t = {
    pid : int32;
    secret_key : int32;
  }
end

type t = {
  decoder : Pgsql_codec.Decode.t;
  buf : Bytes.t;
  scratch : Buffer.t;
  r : Abbs_io_buffered.reader Abbs_io_buffered.t;
  w : Abbs_io_buffered.writer Abbs_io_buffered.t;
  backend_key_data : Backend_key_data.t;
  mutable unique_id : int;
}

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
    let open Abbs_future_combinators.Infix_result_monad in
    let bytes = encode_frame conn.scratch frame in
    Abbs_io_buffered.write conn.w ~bufs:Abb_intf.Write_buf.[ write_buf bytes ]
    >>= fun _ -> Abbs_io_buffered.flushed conn.w

  let rec wait_for_frames conn =
    let open Abbs_future_combinators.Infix_result_monad in
    match Pgsql_codec.Decode.backend_msg conn.decoder ~pos:0 ~len:0 conn.buf with
      | Ok [] ->
          Abbs_io_buffered.read conn.r ~buf:conn.buf ~pos:0 ~len:(Bytes.length conn.buf)
          >>= fun n ->
          wait_for_frames' conn (Pgsql_codec.Decode.backend_msg conn.decoder ~pos:0 ~len:n conn.buf)
      | r     -> wait_for_frames' conn r

  and wait_for_frames' conn = function
    | Ok []     -> wait_for_frames conn
    | Ok _ as r -> Abb.Future.return r
    | Error err -> Abb.Future.return (Error (`Parse_error err))
end

module Typed_sql = struct
  module Var = struct
    type 'a t = 'a -> string list -> string list

    let smallint n vs = string_of_int n :: vs

    let integer n vs = Int32.to_string n :: vs

    let bigint n vs = Int64.to_string n :: vs

    let decimal n vs = Z.to_string n :: vs

    let numeric = decimal

    let real n vs = string_of_float n :: vs

    let double = real

    let smallserial n vs = string_of_int n :: vs

    let serial n vs = Int32.to_string n :: vs

    let bigserial n vs = Int64.to_string n :: vs

    let money n vs = Int64.to_string n :: vs

    let text s vs = s :: vs

    let varchar = text

    let char = text

    let boolean b vs =
      ( if b then
        "true"
      else
        "false" )
      :: vs

    let ud f v vs = f v @ vs
  end

  module Ret = struct
    type 'a t = string list -> ('a * string list) option

    let take_one f = function
      | []      -> None
      | x :: xs -> CCOpt.map (fun v -> (v, xs)) (f x)

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

    let boolean =
      take_one (function
          | "true"  -> Some true
          | "false" -> Some false
          | _       -> None)

    let ud f xs = f xs
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

  let rec kbind' : type q qr p pr. (string list -> qr) -> (q, qr, p, pr) t -> q =
   fun k t ->
    match t with
      | Sql             -> k []
      | Ret (t, _)      -> kbind' k t
      | Const (t, s)    -> kbind' k t
      | Variable (t, v) ->
          kbind'
            (fun vs v' ->
              let ret = v v' vs in
              k ret)
            t

  let kbind : type q qr p pr. (string list -> qr) -> (q, qr, p, pr) t -> q =
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

    let rec kbind' : type f r. f -> string list -> (f, r) t -> r option =
     fun f vs t ->
      match t with
        | Sql when vs = [] -> Some f
        | Sql -> None
        | Ret (t', r) ->
            let open CCOpt.Infix in
            r vs >>= fun (v, vs') -> kbind' f vs' t' >>= fun f' -> Some (f' v)

    let kbind f data t = kbind' f (List.rev data) t
  end

  type ('f, 'fr, 'r) t = {
    func : ('f, 'fr) F.t;
    f : 'fr -> 'f;
    init : 'fr;
    fin : 'fr -> 'r;
  }

  (* let map sql ~f = failwith "nyi"
   * let ignore sql = failwith "nyi" *)

  let make sql ~init ~f ~fin =
    let func = F.t_of_sql sql in
    { func; f; init; fin }
end

module Prepared_stmt = struct
  type create_err =
    [ Abb_io_buffered.read_err
    | Abb_io_buffered.write_err
    | Io.err
    | `Msgs of (char * string) list
    ]
  [@@deriving show, eq]

  type exec_err =
    [ Abb_io_buffered.read_err
    | Abb_io_buffered.write_err
    | Io.err
    ]
  [@@deriving show, eq]

  type destroy_err =
    [ Abb_io_buffered.read_err
    | Abb_io_buffered.write_err
    | Io.err
    ]
  [@@deriving show, eq]

  type conn = t

  type ('q, 'qr, 'p, 'pr) t = {
    conn : conn;
    sql : ('q, 'qr, 'p, 'pr) Typed_sql.t;
    id : string;
  }

  (* Create *)
  let rec create_wait_for_frames conn =
    let open Abbs_future_combinators.Infix_result_monad in
    Io.wait_for_frames conn >>= fun frames -> create_process_frames conn frames

  and create_process_frames conn = function
    | Pgsql_codec.Frame.Backend.ParseComplete :: fs -> create_process_frames conn fs
    | [ Pgsql_codec.Frame.Backend.ReadyForQuery _ ] -> Abb.Future.return (Ok ())
    | [ Pgsql_codec.Frame.Backend.ErrorResponse { msgs } ] -> Abb.Future.return (Error (`Msgs msgs))
    | _ -> assert false

  let create' conn sql =
    let open Abbs_future_combinators.Infix_result_monad in
    let stmt = gen_unique_id conn "s" in
    let query = Typed_sql.to_query sql in
    let frame = Pgsql_codec.Frame.Frontend.(Parse { stmt; query; data_types = [] }) in
    Io.send_frame conn frame
    >>= fun () ->
    Io.send_frame conn Pgsql_codec.Frame.Frontend.Sync
    >>= fun () ->
    create_wait_for_frames conn >>= fun () -> Abb.Future.return (Ok { conn; sql; id = stmt })

  let create conn sql =
    let open Abb.Future.Infix_monad in
    create' conn sql
    >>= function
    | Ok _ as r      -> Abb.Future.return r
    | Error _ as err -> Abb.Future.return err

  (* Execute *)
  let rec sync_complete t rf st =
    let open Abbs_future_combinators.Infix_result_monad in
    Io.wait_for_frames t.conn >>= fun frames -> sync_complete' t rf st frames

  and sync_complete' t rf st = function
    | [] -> sync_complete t rf st
    | Pgsql_codec.Frame.Backend.BindComplete :: fs -> process_row_frames t rf st fs
    | Pgsql_codec.Frame.Backend.ParseComplete :: fs -> sync_complete' t rf st fs
    | _ -> failwith "nyi"

  and recv_rows t rf st =
    let open Abbs_future_combinators.Infix_result_monad in
    Io.wait_for_frames t.conn >>= fun frames -> process_row_frames t rf st frames

  and process_row_frames t rf st = function
    | [] -> recv_rows t rf st
    | Pgsql_codec.Frame.Backend.CommandComplete _ :: _ ->
        (* TODO: Handle tag *)
        rf.Row_func.fin st
    | Pgsql_codec.Frame.Backend.DataRow { data } :: fs -> process_data_frame t rf st fs data
    | Pgsql_codec.Frame.Backend.NoticeResponse _ :: fs ->
        (* TODO: Handle notices *)
        process_row_frames t rf st fs
    | _ -> failwith "nyi"

  and process_data_frame t rf st fs data =
    match Row_func.F.kbind (rf.Row_func.f st) data rf.Row_func.func with
      | Some st -> process_row_frames t rf st fs
      | None    -> failwith "nyi"

  let execute t rf =
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
        Io.send_frame t.conn Pgsql_codec.Frame.Frontend.(Execute { portal; max_rows = Int32.zero })
        >>= fun () ->
        Io.send_frame t.conn Pgsql_codec.Frame.Frontend.Sync
        >>= fun () ->
        let st = rf.Row_func.init in
        sync_complete t rf st)
      t.sql

  let destroy t =
    let open Abbs_future_combinators.Infix_result_monad in
    let frame = Pgsql_codec.Frame.Frontend.(Close { typ = 'S'; name = t.id }) in
    Io.send_frame t.conn frame
    >>= fun () ->
    Io.send_frame t.conn Pgsql_codec.Frame.Frontend.Sync
    >>= fun () ->
    Io.wait_for_frames t.conn
    >>= function
    | [ Pgsql_codec.Frame.Backend.CloseComplete; Pgsql_codec.Frame.Backend.ReadyForQuery _ ] ->
        Abb.Future.return (Ok ())
    | _ -> failwith "nyi"
end

type create_err =
  [ `Unexpected of (exn[@opaque] [@equal ( = )])
  | `Connection_failed
  | `E_access
  | `E_address_family_not_supported
  | `E_address_in_use
  | `E_address_not_available
  | `E_bad_file
  | `E_connection_refused
  | `E_connection_reset
  | `E_host_unreachable
  | `E_invalid
  | `E_io
  | `E_is_connected
  | `E_network_unreachable
  | `E_no_space
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
  Abbs_io_buffered.write w ~bufs:Abb_intf.Write_buf.[ Io.write_buf bytes ]
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
      decoder;
      buf;
      scratch;
      r;
      w;
      backend_key_data = Backend_key_data.{ pid = Int32.zero; secret_key = Int32.zero };
      unique_id = 0;
    }
  in
  let msgs = [ ("user", user); ("database", database) ] in
  let startup = Pgsql_codec.Frame.Frontend.(StartupMessage { msgs }) in
  Io.send_frame t startup >>= fun () -> create_sm_login t

and create_sm_login t =
  let open Abbs_future_combinators.Infix_result_monad in
  Io.wait_for_frames t >>= fun frames -> create_sm_process_login_frames t frames

and create_sm_process_login_frames t =
  let open Pgsql_codec.Frame.Backend in
  function
  | AuthenticationOk :: fs -> create_sm_process_login_frames t fs
  | ParameterStatus _ :: fs -> create_sm_process_login_frames t fs
  | BackendKeyData { pid; secret_key } :: fs ->
      let t = { t with backend_key_data = Backend_key_data.{ pid; secret_key } } in
      create_sm_process_login_frames t fs
  | [ ReadyForQuery _ ] -> Abb.Future.return (Ok t)
  | _ -> failwith "nyi"

let create ?tls_config ?passwd ?(port = 5432) ~host ~user database =
  let open Abb.Future.Infix_monad in
  let tcp = CCResult.get_exn (Abb.Socket.Tcp.create ~domain:Abb_intf.Socket.Domain.Inet4) in
  Abbs_future_combinators.on_failure
    (fun () ->
      create_sm ?tls_config ?passwd ~host ~port ~user database tcp
      >>= function
      | Ok _ as r      -> Abb.Future.return r
      | Error _ as err ->
          Abbs_future_combinators.ignore (Abb.Socket.close tcp) >>= fun () -> Abb.Future.return err)
    ~failure:(fun () -> Abbs_future_combinators.ignore (Abb.Socket.close tcp))

let destroy t = Abbs_io_buffered.close_writer t.w

let tx_commit t =
  let open Abbs_future_combinators.Infix_result_monad in
  Io.send_frame t Pgsql_codec.Frame.Frontend.(Query { query = "COMMIT;" })
  >>= fun () -> Io.send_frame t Pgsql_codec.Frame.Frontend.Sync

let tx_rollback t =
  let open Abbs_future_combinators.Infix_result_monad in
  Io.send_frame t Pgsql_codec.Frame.Frontend.(Query { query = "ROLLBACK;" })
  >>= fun () -> Io.send_frame t Pgsql_codec.Frame.Frontend.Sync

let tx t ~f =
  Abbs_future_combinators.on_failure
    (fun () ->
      let open Abb.Future.Infix_monad in
      Io.send_frame t Pgsql_codec.Frame.Frontend.(Query { query = "BEGIN;" })
      >>= fun _ ->
      Io.send_frame t Pgsql_codec.Frame.Frontend.Sync
      >>= fun _ ->
      (* TODO: Handle send_frame error *)
      f ()
      >>= function
      | Ok _ as r    ->
          let open Abbs_future_combinators.Infix_result_monad in
          tx_commit t >>= fun () -> Abb.Future.return r
      | Error _ as r -> tx_rollback t >>= fun _ -> Abb.Future.return r)
    ~failure:(fun () -> Abbs_future_combinators.ignore (tx_rollback t))
