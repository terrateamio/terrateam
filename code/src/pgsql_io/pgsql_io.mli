(** A connection to the database *)
type t

module Io : sig
  type err = [ `Parse_error of Pgsql_codec.Decode.err ]
end

type frame_err =
  [ `Unmatching_frame of Pgsql_codec.Frame.Backend.t list
  | Io.err
  | `Disconnected
  ]

val show_frame_err : frame_err -> string

type integrity_err = {
  message : string;
  detail : string option;
}

val show_integrity_err : integrity_err -> string

type sql_parse_err =
  [ `Empty_variable_name
  | `Unclosed_quote      of string
  | `Unknown_variable    of string
  ]

val show_sql_parse_err : sql_parse_err -> string

type err =
  [ `Msgs of (char * string) list
  | frame_err
  | `Disconnected
  | `Bad_result of string option list
  | `Integrity_err of integrity_err
  | sql_parse_err
  ]

val pp_err : Format.formatter -> err -> unit

val show_err : err -> string

module Typed_sql : sig
  module Var : sig
    type 'a t

    (** Little wrapper type to include the name *)
    type 'a v = string -> 'a t

    (** Numeric types *)
    val smallint : int v

    val integer : int32 v

    val bigint : int64 v

    val decimal : Z.t v

    val numeric : Z.t v

    val real : float v

    val double : float v

    val smallserial : int v

    val serial : int32 v

    val bigserial : int64 v

    (** Monetary *)
    val money : int64 v

    (** Text types *)
    val text : string v

    val varchar : string v

    val char : string v

    val tsquery : string v

    val uuid : Uuidm.t v

    (** Boolean types *)
    val boolean : bool v

    val date : string v

    val timestamp : string v

    val timestamptz : string v

    val ud : 'b t -> ('a -> 'b) -> 'a t

    val option : 'a t -> 'a option t

    (** Type for any array that is NOT a string.  Strings require a special
       representation that this does not account for. *)
    val array : 'a t -> 'a list t

    (** Any kind of string array. *)
    val str_array : 'a t -> 'a list t
  end

  module Ret : sig
    type 'a t

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

    val money : int64 t

    val text : string t

    val varchar : string t

    val char : string t

    val uuid : Uuidm.t t

    val boolean : bool t

    val ud : (string option list -> ('a * string option list) option) -> 'a t

    val option : 'a t -> 'a option t
  end

  type ('q, 'qr, 'p, 'pr) t

  val sql : ('qr, 'qr, 'pr, 'pr) t

  val ( /^ ) : ('q, 'qr, 'p, 'pr) t -> string -> ('q, 'qr, 'p, 'pr) t

  (** Concatenate the right query to the left. *)
  val ( /^^ ) : ('q, 'qr, 'p, 'pr) t -> ('qr, 'qqr, 'pr, 'ppr) t -> ('q, 'qqr, 'p, 'ppr) t

  val ( /% ) : ('q, 'a -> 'qr, 'p, 'pr) t -> 'a Var.t -> ('q, 'qr, 'p, 'pr) t

  val ( // ) : ('q, 'qr, 'p, 'a -> 'pr) t -> 'a Ret.t -> ('q, 'qr, 'p, 'pr) t

  val to_query : ('q, 'qr, 'p, 'pr) t -> (string, sql_parse_err) result

  val kbind : (string option list -> 'qr) -> ('q, 'qr, 'p, 'pr) t -> 'q
end

module Row_func : sig
  type ('f, 'fr, 'acc, 'r) t

  val make :
    ('q, 'qr, 'p, 'pr) Typed_sql.t ->
    init:'acc ->
    f:('acc -> 'p) ->
    post_f:('acc -> 'pr -> 'acc) ->
    fin:('acc -> 'r) ->
    ('p, 'pr, 'acc, 'r) t

  val ignore : ('q, 'qr, unit, unit) Typed_sql.t -> (unit, unit, unit, unit) t

  val fold : ('q, 'qr, 'p, 'r) Typed_sql.t -> init:'r -> f:('r -> 'p) -> ('p, 'r, 'r, 'r) t

  val map : ('q, 'qr, 'p, 'r) Typed_sql.t -> f:'p -> ('p, 'r, 'r list, 'r list) t
end

module Cursor : sig
  type ('p, 'pr, 'acc, 'qr) t

  val execute : ('p, 'pr, 'acc, unit) t -> (unit, [> err ]) result Abb.Future.t

  val fetch : ?n:int -> ('p, 'pr, 'acc, 'r list) t -> ('r list, [> err ]) result Abb.Future.t

  val destroy : ('p, 'pr, 'acc, 'qr) t -> (unit, [> err ]) result Abb.Future.t

  val with_cursor :
    ('p, 'pr, 'acc, 'qr) t ->
    f:(('p, 'pr, 'acc, 'qr) t -> ('a, ([> err ] as 'e)) result Abb.Future.t) ->
    ('a, 'e) result Abb.Future.t
end

module Prepared_stmt : sig
  type conn = t

  type ('q, 'qr, 'p, 'pr) t

  val create :
    conn -> ('q, 'qr, 'p, 'pr) Typed_sql.t -> (('q, 'qr, 'p, 'pr) t, [> err ]) result Abb.Future.t

  val bind :
    ('q, (('p, 'pr, 'acc, 'r) Cursor.t, [> err ]) result Abb.Future.t, 'p, 'pr) t ->
    ('p, 'pr, 'acc, 'r) Row_func.t ->
    'q

  (** Perform the create, bind, cursor execute, and cleanup of an SQL statement. *)
  val execute : conn -> ('q, (unit, [> err ]) result Abb.Future.t, unit, unit) Typed_sql.t -> 'q

  (** Perform the bind and execute, useful when executing the same statement
     multiple times. *)
  val bind_execute : ('q, (unit, [> err ]) result Abb.Future.t, unit, unit) t -> 'q

  (** Perform the create, bind, cursor fetch, and cleanup of an SQL statement. *)
  val fetch :
    conn -> ('q, ('r list, [> err ]) result Abb.Future.t, 'p, 'r) Typed_sql.t -> f:'p -> 'q

  val destroy : ('q, 'qr, 'p, 'pr) t -> (unit, [> err ]) result Abb.Future.t

  val kbind :
    conn ->
    ('q, ('ret, ([> err ] as 'err)) result Abb.Future.t, 'p, 'pr) Typed_sql.t ->
    ('p, 'pr, 'acc, 'r) Row_func.t ->
    (('p, 'pr, 'acc, 'r) Cursor.t -> ('ret, 'err) result Abb.Future.t) ->
    'q
end

type create_err =
  [ `Unexpected of exn
  | `Connection_failed
  | Io.err
  ]

val create :
  ?tls_config:[ `Require of Otls.Tls_config.t | `Prefer  of Otls.Tls_config.t ] ->
  ?passwd:string ->
  ?port:int ->
  ?notice_response:((char * string) list -> unit) ->
  host:string ->
  user:string ->
  string ->
  (t, [> create_err ]) result Abb.Future.t

val destroy : t -> unit Abb.Future.t

(** Return if the connection is considered connected.  A connection can be set
   to disconnected by an earlier operation failing.  This does not perform any
   network operations to test if the connection is still alive. *)
val connected : t -> bool

(** Perform a network operation to test if the connection is alive.  Return
   [true] if it succeeds and [false] if it not.  This also sets [connected] to
   [false] if the connection is not alive. *)
val ping : t -> bool Abb.Future.t

val tx : t -> f:(unit -> ('a, ([> err ] as 'e)) result Abb.Future.t) -> ('a, 'e) result Abb.Future.t

(** Printers *)
val pp_create_err : Format.formatter -> create_err -> unit

val show_create_err : create_err -> string

(** Equaity *)
val equal_create_err : create_err -> create_err -> bool
