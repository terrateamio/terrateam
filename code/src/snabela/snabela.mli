(** Logic-less template replacement. *)

(** [Kv] represents the values to be used in during replacement in a template.
    There are two classes: scalars and lists.  Only scalars can be used in
    replacement.  Lists can be iterated.

    Convenience function are provided for constructing a value of type [t] as
    well as pretty printing. *)
module Kv : sig
  module Map : CCMap.S with type key = string

  type scalar =
    | I of int
    | F of float
    | S of string
    | B of bool

  type t =
    | V of scalar
    | L of t Map.t list

  val list : t Map.t list -> t
  val int : int -> t
  val float : float -> t
  val string : string -> t
  val bool : bool -> t

  val pp : Format.formatter -> t -> unit
  val show : t -> string
  val equal : t -> t -> bool
end

module Transformer : sig
  type t = (string * (Kv.scalar -> Kv.scalar))
end

module Template : sig
  type err = [ `Exn of exn | Snabela_lexer.err ]

  type t

  (** Parse a template string that is UTF-8 encoded. *)
  val of_utf8_string : string -> (t, [> err ]) result
end

type line_number = int

(** Error type when applying a key-value to a template.  When necessary, the
    line number in the template is included in the error. *)
type err = [ `Missing_key of (string * line_number) (** Key was missing on the line *)
           | `Expected_boolean of (string * line_number) (** Expected a boolean in a section. *)
           | `Expected_list of (string * line_number) (** Expected a list in a section. *)
           | `Missing_transformer of (string * line_number) (** Transformer was not found. *)
           | `Non_scalar_key of (string * line_number) (** Non-scalar value used in  replacement *)
           | `Premature_eof (** Reached an unexpected EOF. *)
           | `Missing_closing_section of string (** Failed to provide a close for the section. *)
           ]

(** A compiled representation of a parsed template and transformers. *)
type t

(** Standard function to convert a scalar into a string. *)
val string_of_scalar : Kv.scalar -> string

(** Turn a parsed template and transformers into a compiled representation that
    can be applied to a kv.

    The [append_transformers] parameter contains transformers that will be
    applied to every replacement. *)
val of_template :
  ?append_transformers:(Kv.scalar -> Kv.scalar) list ->
  Template.t ->
  Transformer.t list ->
  t

(** Apply a key-value to a template turning it into a string or an error. *)
val apply : t -> Kv.t Kv.Map.t -> (string, [> err ]) result

(** Pretty print an error. *)
val pp_err : Format.formatter -> err -> unit

(** Turn an error into a string. *)
val show_err : err -> string
