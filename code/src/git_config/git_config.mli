module Key : sig
  type t

  val section : string -> t
  val subsection : string -> string -> t
end

type t

type err =
  [ `Premature_eof_err
  | `Syntax_err of int
  ]
[@@deriving show]

val empty : t
val of_string : string -> (t, [> err ]) result
val to_list : t -> (Key.t * (string * string list) list) list
val value : Key.t -> string -> t -> string list option
