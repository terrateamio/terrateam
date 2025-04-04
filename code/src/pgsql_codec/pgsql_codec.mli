module Frame : sig
  module Backend : sig
    type row = {
      name : string;
      table_id : int32;
      column_attr : int;
      data_type_id : int32;
      data_type_size : int;
      data_type_mod : int32;
      format_code : int;
    }

    type t =
      | AuthenticationOk
      | AuthenticationKerberosV5
      | AuthenticationCleartextPassword
      | AuthenticationMD5Password of { salt : string }
      | AuthenticationSCMCredential
      | AuthenticationGSS
      | AuthenticationSSPI
      | AuthenticationGSSContinue of { data : string }
      | AuthenticationSASL of { auth_mechanisms : string list }
      | AuthenticationSASLContinue of { data : string }
      | AuthenticationSASLFinal of { data : string }
      | BackendKeyData of {
          pid : int32;
          secret_key : int32;
        }
      | BindComplete
      | CloseComplete
      | CommandComplete of { tag : string }
      | CopyData of { data : string }
      | CopyDone
      | CopyInResponse (* TODO *)
      | CopyOutResponse (* TODO *)
      | CopyBothResponse (* TODO *)
      | DataRow of { data : string option list }
      | EmptyQueryResponse
      | ErrorResponse of { msgs : (char * string) list }
      | FunctionCallResponse (* TODO *)
      | NegotiateProtocolVersion of {
          minor_version : int32;
          unrecognized_options : string list;
        }
      | NoData
      | NoticeResponse of { msgs : (char * string) list }
      | NotificationResponse of {
          pid : int32;
          channel : string;
          payload : string;
        }
      | ParameterDescription of { object_ids : int32 list }
      | ParameterStatus of {
          name : string;
          value : string;
        }
      | ParseComplete
      | PortalSuspended
      | ReadyForQuery of { status : char }
      | RowDescription of { rows : row list }

    (** Printers *)
    val pp : Format.formatter -> t -> unit

    val show : t -> string
    val pp_row : Format.formatter -> row -> unit
    val show_row : row -> string

    (** Equality *)
    val equal : t -> t -> bool

    val equal_row : row -> row -> bool
  end

  module Frontend : sig
    type t =
      | Bind of {
          portal : string;
          stmt : string;
          format_codes : bool list;
          values : string option list;
          result_format_codes : bool list;
        }
      | CancelRequest of {
          pid : int32;
          secret_key : int32;
        }
      | Close of {
          typ : char;
          name : string;
        }
      | CopyData (* TODO *)
      | CopyDone (* TODO *)
      | CopyFail (* TODO *)
      | Describe of {
          typ : char;
          name : string;
        }
      | Execute of {
          portal : string;
          max_rows : int32;
        }
      | Flush
      | FunctionCall (* TODO *)
      | GSSResponse of { data : string }
      | Parse of {
          stmt : string;
          query : string;
          data_types : int32 list;
        }
      | PasswordMessage of { password : string }
      | Query of { query : string }
      | SASLInitialResponse of {
          auth_mechanism : string;
          data : string;
        }
      | SASLResponse of { data : string }
      | SSLRequest
      | StartupMessage of { msgs : (string * string) list }
      | Sync
      | Terminate

    (** Printers *)
    val pp : Format.formatter -> t -> unit

    val show : t -> string

    (** Equality *)
    val equal : t -> t -> bool
  end
end

module Decode : sig
  type err =
    [ `Unknown_type of char
    | `Invalid_frame
    ]

  type t

  val create : unit -> t

  (** Given a sequence of bytes, decode them into a list of frames. If there is the bytes do not
      encode a complete frame, the empty list is returned. If the bytes do not decode to a valid
      frame, then any correctly decoded frames will be returned and subsequent calls will return an
      error. *)
  val backend_msg : t -> pos:int -> len:int -> Bytes.t -> (Frame.Backend.t list, err) result

  (** Given a sequence of bytes, decode them into a list of frames. If there is the bytes do not
      encode a complete frame, the empty list is returned. If the bytes do not decode to a valid
      frame, then any correctly decoded frames will be returned and subsequent calls will return an
      error. *)
  val frontend_msg : t -> pos:int -> len:int -> Bytes.t -> (Frame.Frontend.t list, err) result

  (** How many bytes the decode needs to continue, if it knows it. *)
  val needed_bytes : t -> int option

  (** How many bytes are in the buffer that has been accumulated. *)
  val buffer_length : t -> int

  (** Printers *)
  val pp_err : Format.formatter -> err -> unit

  val show_err : err -> string

  (** Equality *)
  val equal_err : err -> err -> bool
end

module Encode : sig
  val backend_msg : Buffer.t -> Frame.Backend.t -> unit
  val frontend_msg : Buffer.t -> Frame.Frontend.t -> unit
end
