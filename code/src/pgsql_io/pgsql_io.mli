(** A connection to the database *)
type t

module Io : sig
  type err = [ `Parse_error of Pgsql_codec.Decode.err ]
end

type frame_err =
  [ `Unmatching_frame of Pgsql_codec.Frame.Backend.t
  | Io.err
  ]

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

  val make :
    ('q, 'qr, 'p, 'pr) Typed_sql.t ->
    init:'pr ->
    f:('pr -> 'p) ->
    fin:('pr -> 'r) ->
    ('p, 'pr, 'r) t

  val ignore : ('q, 'qr, unit, unit) Typed_sql.t -> (unit, unit, unit) t

  val map : ('q, 'qr, 'p, 'r list) Typed_sql.t -> ('r list -> 'p) -> ('p, 'r list, 'r list) t
end

module Cursor : sig
  type err =
    [ Abb_io_buffered.read_err
    | Abb_io_buffered.write_err
    | Io.err
    | frame_err
    | `Msgs of (char * string) list
    ]

  type ('p, 'pr, 'qr) t

  val execute : ('p, 'pr, unit) t -> (unit, [> err ]) result Abb.Future.t

  val fetch : ?n:int -> ('p, 'pr, 'r list) t -> ('r list, [> err ]) result Abb.Future.t

  val destroy : ('p, 'pr, 'qr) t -> (unit, [> err ]) result Abb.Future.t

  val with_cursor :
    ('p, 'pr, 'qr) t ->
    f:(('p, 'pr, 'qr) t -> ('a, ([> err ] as 'e)) result Abb.Future.t) ->
    ('a, 'e) result Abb.Future.t
end

module Prepared_stmt : sig
  type create_err =
    [ Abb_io_buffered.read_err
    | Abb_io_buffered.write_err
    | Io.err
    | `Msgs of (char * string) list
    | frame_err
    ]

  type bind_err =
    [ Abb_io_buffered.read_err
    | Abb_io_buffered.write_err
    | Io.err
    | frame_err
    | `Msgs of (char * string) list
    ]

  type destroy_err =
    [ Abb_io_buffered.read_err
    | Abb_io_buffered.write_err
    | Io.err
    | frame_err
    | `Msgs of (char * string) list
    ]

  type conn = t

  type ('q, 'qr, 'p, 'pr) t

  val create :
    conn ->
    ('q, 'qr, 'p, 'pr) Typed_sql.t ->
    (('q, 'qr, 'p, 'pr) t, [> create_err ]) result Abb.Future.t

  val bind :
    ('q, (('p, 'pr, 'r) Cursor.t, [> bind_err ]) result Abb.Future.t, 'p, 'pr) t ->
    ('p, 'pr, 'r) Row_func.t ->
    'q

  val destroy : ('q, 'qr, 'p, 'pr) t -> (unit, [> destroy_err ]) result Abb.Future.t

  (** Printers *)
  val pp_create_err : Format.formatter -> create_err -> unit

  val show_create_err : create_err -> string

  val pp_bind_err : Format.formatter -> bind_err -> unit

  val show_bind_err : bind_err -> string

  val pp_destroy_err : Format.formatter -> destroy_err -> unit

  val show_destroy_err : destroy_err -> string

  (** Equality *)
  val equal_create_err : create_err -> create_err -> bool

  val equal_bind_err : bind_err -> bind_err -> bool

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
  f:(unit -> ('a, ([> Abb_io_buffered.write_err | frame_err ] as 'e)) result Abb.Future.t) ->
  ('a, 'e) result Abb.Future.t

(** Printers *)
val pp_create_err : Format.formatter -> create_err -> unit

val show_create_err : create_err -> string

(** Equaity *)
val equal_create_err : create_err -> create_err -> bool
