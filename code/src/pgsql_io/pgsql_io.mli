(** A connection to the database *)
type t

module Io : sig
  type err = [ `Parse_error of Pgsql_codec.Decode.err ]
end

module Typed_sql : sig
  module Var : sig
    type 'a t

    (** Numeric types *)
    val smallint : int t

    val integer : int32 t

    val bigint : int64 t

    val decimal : Z.t t

    val numeric : Z.t t

    val real : float t

    val double : float t

    val smallserial : int t

    val serial : int32 t

    val bigserial : int64 t

    (** Monetary *)
    val money : int64 t

    (** Text types *)
    val text : string t

    val varchar : string t

    val char : string t

    (** Boolean types *)
    val boolean : bool t

    val ud : ('a -> string list) -> 'a t
  end

  module Ret : sig
    type 'a t

    (** Numeric types *)
    val smallint : int t

    val integer : int32 t

    val bigint : int64 t

    val decimal : Z.t t

    val numeric : Z.t t

    val real : float t

    val double : float t

    val smallserial : int t

    val serial : int32 t

    val bigserial : int64 t

    (** Monetary *)
    val money : int64 t

    (** Text types *)
    val text : string t

    val varchar : string t

    val char : string t

    (** Boolean types *)
    val boolean : bool t

    val ud : (string list -> ('a * string list) option) -> 'a t
  end

  type ('q, 'qr, 'p, 'pr) t

  val sql : ('qr, 'qr, 'pr, 'pr) t

  val ( /^ ) : ('q, 'qr, 'p, 'pr) t -> string -> ('q, 'qr, 'p, 'pr) t

  val ( /% ) : ('q, 'a -> 'qr, 'p, 'pr) t -> 'a Var.t -> ('q, 'qr, 'p, 'pr) t

  val ( // ) : ('q, 'qr, 'p, 'a -> 'pr) t -> 'a Ret.t -> ('q, 'qr, 'p, 'pr) t

  val to_query : ('q, 'qr, 'p, 'pr) t -> string
end

module Row_func : sig
  type ('f, 'fr, 'r) t

  (* val map : ('q, 'qr, 'f, 'r) Typed_sql.t -> f:'f -> ('f, 'r list) t
   * val ignore : ('q, 'qr, 'f, 'r) Typed_sql.t -> ('f, unit) t *)

  val make :
    ('q, 'qr, 'p, 'pr) Typed_sql.t ->
    init:'pr ->
    f:('pr -> 'p) ->
    fin:('pr -> 'qr) ->
    ('p, 'pr, 'qr) t
end

module Prepared_stmt : sig
  type create_err =
    [ Abb_io_buffered.read_err
    | Abb_io_buffered.write_err
    | Io.err
    | `Msgs of (char * string) list
    ]

  type exec_err =
    [ Abb_io_buffered.read_err
    | Abb_io_buffered.write_err
    | Io.err
    ]

  type destroy_err =
    [ Abb_io_buffered.read_err
    | Abb_io_buffered.write_err
    | Io.err
    ]

  type conn = t

  type ('q, 'qr, 'p, 'pr) t

  val create :
    conn ->
    ('q, 'qr, 'p, 'pr) Typed_sql.t ->
    (('q, 'qr, 'p, 'pr) t, [> create_err ]) result Abb.Future.t

  val execute :
    ('q, ('r, exec_err) result Abb.Future.t, 'p, 'pr) t ->
    ('p, 'pr, ('r, exec_err) result Abb.Future.t) Row_func.t ->
    'q

  val destroy : ('q, 'qr, 'p, 'pr) t -> (unit, [> destroy_err ]) result Abb.Future.t

  (** Printers *)
  val pp_create_err : Format.formatter -> create_err -> unit

  val show_create_err : create_err -> string

  val pp_exec_err : Format.formatter -> exec_err -> unit

  val show_exec_err : exec_err -> string

  val pp_destroy_err : Format.formatter -> destroy_err -> unit

  val show_destroy_err : destroy_err -> string

  (** Equality *)
  val equal_create_err : create_err -> create_err -> bool

  val equal_exec_err : exec_err -> exec_err -> bool

  val equal_destroy_err : destroy_err -> destroy_err -> bool
end

type create_err =
  [ `Unexpected of exn
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

val create :
  ?tls_config:[ `Require of Otls.Tls_config.t | `Prefer  of Otls.Tls_config.t ] ->
  ?passwd:string ->
  ?port:int ->
  host:string ->
  user:string ->
  string ->
  (t, [> create_err ]) result Abb.Future.t

val destroy : t -> (unit, [> `E_io | `E_no_space | `Unexpected of exn ]) result Abb.Future.t

val tx :
  t ->
  f:(unit -> ('a, ([> Abb_io_buffered.write_err ] as 'e)) result Abb.Future.t) ->
  ('a, 'e) result Abb.Future.t

(** Printers *)
val pp_create_err : Format.formatter -> create_err -> unit

val show_create_err : create_err -> string

(** Equaity *)
val equal_create_err : create_err -> create_err -> bool
