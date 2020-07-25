module Var : sig
  type v =
    | S of string
    | A of string list
    | M of (string * string) list

  type t = string * v
end

type t

type parse_err = [ `Error ]

val of_string : string -> (t, [> parse_err ]) result

val to_string : t -> string

val expand : t -> Var.t list -> string
