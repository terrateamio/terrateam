module Reader : sig
  type err =
    [ `Unknown_type  of char
    | `Length
    | `Invalid_frame
    ]

  type 'a t

  val run : buf:Bytes.t -> pos:int -> len:int -> 'a t -> ('a * int, err * int) result

  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t

  val return : 'a -> 'a t

  val fail : err -> 'a t

  val int32 : int32 t

  val bytes : int -> string t

  val string : string t

  val int16 : int t

  val repeat : int -> 'a t -> 'a list t

  val consume : int -> 'a t -> 'a list t
end = struct
  module State = struct
    type t = {
      buf : Bytes.t;
      pos : int;
      stop : int;
    }
  end

  type err =
    [ `Unknown_type  of char
    | `Length
    | `Invalid_frame
    ]

  type 'a t = State.t -> ('a, err) result * State.t

  let ( >>= ) t f st =
    match t st with
      | (Ok v, st)        -> f v st
      | (Error _, _) as r -> r

  let return v st = (Ok v, st)

  let fail err st = (Error err, st)

  let run ~buf ~pos ~len t =
    let st = State.{ buf; pos; stop = pos + len } in
    assert (st.State.stop <= Bytes.length buf);
    match t st with
      | (Error (_ as err), st) -> Error (err, st.State.pos)
      | (Ok v, st)             -> Ok (v, st.State.pos)

  let int32 st =
    if st.State.pos + 4 <= st.State.stop then
      let n = EndianBytes.BigEndian.get_int32 st.State.buf st.State.pos in
      (Ok n, { st with State.pos = st.State.pos + 4 })
    else
      (Error `Length, st)

  let bytes n st =
    assert (n > 0);
    if st.State.pos + n <= st.State.stop then
      let s = Bytes.sub_string st.State.buf st.State.pos n in
      (Ok s, { st with State.pos = st.State.pos + n })
    else
      (Error `Length, st)

  let string st =
    match Bytes.index_from_opt st.State.buf st.State.pos '\000' with
      | Some idx when idx + 1 < st.State.stop ->
          let s = Bytes.sub_string st.State.buf st.State.pos (idx - st.State.pos) in
          (* +1 to consume the end null byte *)
          (Ok s, { st with State.pos = st.State.pos + (idx - st.State.pos) + 1 })
      | _ -> (Error `Length, st)

  let int16 st =
    if st.State.pos + 2 <= st.State.stop then
      let n = EndianBytes.BigEndian.get_int16 st.State.buf st.State.pos in
      (Ok n, { st with State.pos = st.State.pos + 2 })
    else
      (Error `Length, st)

  let rec repeat n t st =
    if n > 0 then
      match t st with
        | (Ok v, st)             -> (
            match repeat (n - 1) t st with
              | (Ok vs, st)            -> (Ok (v :: vs), st)
              | ((Error _ as err), st) -> (err, st) )
        | ((Error _ as err), st) -> (err, st)
    else
      (Ok [], st)

  let rec consume len t st =
    if len > 0 then
      let pos = st.State.pos in
      match t st with
        | (Ok v, st)             -> (
            let consumed = st.State.pos - pos in
            let len = len - consumed in
            match consume len t st with
              | (Ok vs, st)            -> (Ok (v :: vs), st)
              | ((Error _ as err), st) -> (err, st) )
        | ((Error _ as err), st) -> (err, st)
    else
      (Ok [], st)
end

module Writer : sig
  type t

  val run : Buffer.t -> t -> unit

  val msg_code : char -> t

  val int32 : int32 -> t

  val int16 : int -> t

  val bytes : string -> t

  val string : string -> t

  val chr : char -> t

  val iter : ('a -> t) -> 'a list -> t

  val ( >>= ) : t -> (unit -> t) -> t
end = struct
  type t = Buffer.t * Buffer.t -> unit

  let msg_code ch (b, _) = Buffer.add_char b ch

  let int32 n (_, buf) =
    let b = Bytes.create 4 in
    EndianBytes.BigEndian.set_int32 b 0 n;
    Buffer.add_bytes buf b

  let int16 n (_, buf) =
    let b = Bytes.create 2 in
    EndianBytes.BigEndian.set_int16 b 0 n;
    Buffer.add_bytes buf b

  let bytes s (_, buf) = Buffer.add_string buf s

  let string s (_, buf) =
    Buffer.add_string buf s;
    Buffer.add_char buf '\000'

  let chr ch (_, buf) = Buffer.add_char buf ch

  let iter f xs bs = List.iter (fun x -> f x bs) xs

  let run prepend_buf t =
    let buf = Buffer.create 1024 in
    t (prepend_buf, buf);
    let len = 4 + Buffer.length buf in
    int32 (Int32.of_int len) (prepend_buf, prepend_buf);
    Buffer.add_buffer prepend_buf buf

  let ( >>= ) t f buf =
    let r = t buf in
    f r buf
end

module Frame = struct
  module Backend = struct
    type row = {
      name : string;
      table_id : int32;
      column_attr : int;
      data_type_id : int32;
      data_type_size : int;
      data_type_mod : int32;
      format_code : int;
    }
    [@@deriving show, eq]

    type t =
      | AuthenticationOk
      | AuthenticationKerberosV5
      | AuthenticationCleartextPassword
      | AuthenticationMD5Password       of { salt : string }
      | AuthenticationSCMCredential
      | AuthenticationGSS
      | AuthenticationSSPI
      | AuthenticationGSSContinue       of { data : string }
      | AuthenticationSASL              of { auth_mechanism : string }
      | AuthenticationSASLContinue      of { data : string }
      | AuthenticationSASLFinal         of { data : string }
      | BackendKeyData                  of {
          pid : int32;
          secret_key : int32;
        }
      | BindComplete
      | CloseComplete
      | CommandComplete                 of { tag : string }
      | CopyData                        of { data : string }
      | CopyDone
      | CopyInResponse (* TODO *)
      | CopyOutResponse (* TODO *)
      | CopyBothResponse (* TODO *)
      | DataRow                         of { data : string list }
      | EmptyQueryResponse
      | ErrorResponse                   of { msgs : (char * string) list }
      | FunctionCallResponse (* TODO *)
      | NegotiateProtocolVersion        of {
          minor_version : int32;
          unrecognized_options : string list;
        }
      | NoData
      | NoticeResponse                  of { msgs : (char * string) list }
      | NotificationResponse            of {
          pid : int32;
          channel : string;
          payload : string;
        }
      | ParameterDescription            of { object_ids : int32 list }
      | ParameterStatus                 of {
          name : string;
          value : string;
        }
      | ParseComplete
      | PortalSuspended
      | ReadyForQuery                   of { status : char }
      | RowDescription                  of { rows : row list }
    [@@deriving show, eq]
  end

  module Frontend = struct
    type t =
      | Bind                of {
          portal : string;
          stmt : string;
          format_codes : bool list;
          values : string list;
          result_format_codes : bool list;
        }
      | CancelRequest       of {
          pid : int32;
          secret_key : int32;
        }
      | Close               of {
          typ : char;
          name : string;
        }
      | CopyData (* TODO *)
      | CopyDone (* TODO *)
      | CopyFail (* TODO *)
      | Describe            of {
          typ : char;
          name : string;
        }
      | Execute             of {
          portal : string;
          max_rows : int32;
        }
      | Flush
      | FunctionCall (* TODO *)
      | GSSResponse         of { data : string }
      | Parse               of {
          stmt : string;
          query : string;
          data_types : int32 list;
        }
      | PasswordMessage     of { password : string }
      | Query               of { query : string }
      | SASLInitialResponse of {
          auth_mechanism : string;
          data : string;
        }
      | SASLResponse        of { data : string }
      | SSLRequest
      | StartupMessage      of { msgs : (string * string) list }
      | Sync
      | Terminate
    [@@deriving show, eq]
  end
end

module Decode = struct
  type err =
    [ `Unknown_type  of char
    | `Invalid_frame
    ]
  [@@deriving show, eq]

  type t = Buffer.t

  let create () = Buffer.create 4096

  let dispatch_backend_msg len =
    let open Reader in
    let open Frame.Backend in
    function
    | 'R' -> (
        int32
        >>= fun n ->
        match Int32.to_int n with
          | 0  -> return AuthenticationOk
          | 2  -> return AuthenticationKerberosV5
          | 3  -> return AuthenticationCleartextPassword
          | 5  -> bytes 4 >>= fun salt -> return (AuthenticationMD5Password { salt })
          | 6  -> return AuthenticationSCMCredential
          | 7  -> return AuthenticationGSS
          | 9  -> return AuthenticationSSPI
          | 8  -> bytes (len - 4) >>= fun data -> return (AuthenticationGSSContinue { data })
          | 10 -> string >>= fun auth_mechanism -> return (AuthenticationSASL { auth_mechanism })
          | 11 -> bytes (len - 4) >>= fun data -> return (AuthenticationSASLContinue { data })
          | 12 -> bytes (len - 4) >>= fun data -> return (AuthenticationSASLFinal { data })
          | _  -> fail `Invalid_frame )
    | 'K' ->
        int32 >>= fun pid -> int32 >>= fun secret_key -> return (BackendKeyData { pid; secret_key })
    | '2' -> return BindComplete
    | '3' -> return CloseComplete
    | 'C' -> string >>= fun tag -> return (CommandComplete { tag })
    | 'G' -> failwith "nyi"
    | 'H' -> failwith "nyi"
    | 'W' -> failwith "nyi"
    | 'D' ->
        int16
        >>= fun columns ->
        assert (columns > 0);
        repeat columns (int32 >>= fun n -> bytes (Int32.to_int n))
        >>= fun data -> return (DataRow { data })
    | 'I' -> return EmptyQueryResponse
    | 'E' ->
        consume (len - 4) (bytes 1 >>= fun code -> string >>= fun msg -> return (code.[0], msg))
        >>= fun msgs ->
        bytes 1
        >>= fun s ->
        assert (s.[0] = '\000');
        return (ErrorResponse { msgs })
    | 'V' -> failwith "nyi"
    | 'v' ->
        int32
        >>= fun minor_version ->
        int32
        >>= fun n ->
        repeat (Int32.to_int n) string
        >>= fun unrecognized_options ->
        return (NegotiateProtocolVersion { minor_version; unrecognized_options })
    | 'n' -> return NoData
    | 'N' ->
        consume (len - 4) (bytes 1 >>= fun code -> string >>= fun msg -> return (code.[0], msg))
        >>= fun msgs ->
        bytes 1
        >>= fun s ->
        assert (s.[0] = '\000');
        return (NoticeResponse { msgs })
    | 'A' ->
        int32
        >>= fun pid ->
        string
        >>= fun channel ->
        string >>= fun payload -> return (NotificationResponse { pid; channel; payload })
    | 't' ->
        int16
        >>= fun n ->
        repeat n int32 >>= fun object_ids -> return (ParameterDescription { object_ids })
    | 'S' -> string >>= fun name -> string >>= fun value -> return (ParameterStatus { name; value })
    | '1' -> return ParseComplete
    | 's' -> return PortalSuspended
    | 'Z' -> bytes 1 >>= fun status -> return (ReadyForQuery { status = status.[0] })
    | 'T' ->
        int16
        >>= fun num_fields ->
        repeat
          num_fields
          ( string
          >>= fun name ->
          int32
          >>= fun table_id ->
          int16
          >>= fun column_attr ->
          int32
          >>= fun data_type_id ->
          int16
          >>= fun data_type_size ->
          int32
          >>= fun data_type_mod ->
          int16
          >>= fun format_code ->
          return
            {
              name;
              table_id;
              column_attr;
              data_type_id;
              data_type_size;
              data_type_mod;
              format_code;
            } )
        >>= fun rows -> return (RowDescription { rows })
    | t   -> fail (`Unknown_type t)

  let rec backend_msg' pos buf len =
    assert (pos >= 0);
    assert (len >= 0);
    assert (len <= Bytes.length buf);
    let res =
      Reader.run
        ~buf
        ~pos
        ~len
        Reader.(
          bytes 1
          >>= fun msg_typ ->
          int32 >>= fun len -> dispatch_backend_msg (Int32.to_int len - 4) msg_typ.[0])
    in
    match res with
      | Ok (frame, pos') -> (
          match backend_msg' pos' buf (len - (pos' - pos)) with
            | Ok (frames, pos)           -> Ok (frame :: frames, pos)
            | Error (frames, `Length, _) -> Ok (frame :: frames, pos')
            | Error (frames, err, pos)   -> Error (frame :: frames, err, pos) )
      | Error (err, _)   -> Error ([], err, pos)

  let backend_msg t ~pos ~len buf =
    let (buf, pos, len) =
      if Buffer.length t = 0 then
        (buf, pos, len)
      else (
        Buffer.add_subbytes t buf pos len;
        let b = Buffer.to_bytes t in
        (b, 0, Bytes.length b)
      )
    in
    match backend_msg' pos buf len with
      | Error ([], (`Unknown_type _ as err), _) | Error ([], (`Invalid_frame as err), _) ->
          Error err
      | Error (frames, _, pos) | Ok (frames, pos) ->
          Buffer.clear t;
          Buffer.add_subbytes t buf pos (len - pos);
          Ok frames

  let frontend_msg t ~pos ~len buf = failwith "nyi"
end

module Encode = struct
  let backend_msg buf frame = failwith "nyi"

  let frontend_msg' =
    let open Writer in
    let open Frame.Frontend in
    function
    | Bind { portal; stmt; format_codes; values; result_format_codes } ->
        msg_code 'B'
        >>= fun () ->
        string portal
        >>= fun () ->
        string stmt
        >>= fun () ->
        int16 (List.length format_codes)
        >>= fun () ->
        iter
          (fun b ->
            int16
              ( if b then
                1
              else
                0 ))
          format_codes
        >>= fun () ->
        int16 (List.length values)
        >>= fun () ->
        iter (fun s -> int32 (Int32.of_int (String.length s)) >>= fun () -> bytes s) values
        >>= fun () ->
        int16 (List.length result_format_codes)
        >>= fun () ->
        iter
          (fun b ->
            int16
              ( if b then
                1
              else
                0 ))
          result_format_codes
    | CancelRequest { pid; secret_key } ->
        int32 (Int32.of_string "80877102") >>= fun () -> int32 pid >>= fun () -> int32 secret_key
    | Close { typ; name } -> msg_code 'C' >>= fun () -> chr typ >>= fun () -> string name
    | CopyData | CopyDone | CopyFail -> failwith "nyi"
    | Describe { typ; name } -> msg_code 'D' >>= fun () -> chr typ >>= fun () -> string name
    | Execute { portal; max_rows } ->
        msg_code 'E' >>= fun () -> string portal >>= fun () -> int32 max_rows
    | Flush -> msg_code 'H'
    | FunctionCall -> failwith "nyi"
    | GSSResponse { data } -> msg_code 'p' >>= fun () -> bytes data
    | Parse { stmt; query; data_types } ->
        msg_code 'P'
        >>= fun () ->
        string stmt
        >>= fun () ->
        string query
        >>= fun () -> int16 (List.length data_types) >>= fun () -> iter int32 data_types
    | PasswordMessage { password } -> msg_code 'p' >>= fun () -> string password
    | Query { query } -> msg_code 'Q' >>= fun () -> string query
    | SASLInitialResponse { auth_mechanism; data } ->
        msg_code 'p'
        >>= fun () ->
        string auth_mechanism
        >>= fun () -> int32 (Int32.of_int (String.length data)) >>= fun () -> bytes data
    | SASLResponse { data } -> msg_code 'p' >>= fun () -> bytes data
    | SSLRequest -> int32 (Int32.of_string "80877103")
    | StartupMessage { msgs } ->
        int32 (Int32.of_string "196608")
        >>= fun () ->
        iter (fun (k, v) -> string k >>= fun () -> string v) msgs >>= fun () -> bytes "\000"
    | Sync -> msg_code 'S'
    | Terminate -> msg_code 'X'

  let frontend_msg buf frame =
    let writer = frontend_msg' frame in
    Writer.run buf writer
end
