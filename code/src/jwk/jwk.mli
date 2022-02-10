module Key : sig
  type t

  val get : string -> t -> string option
end

type t

val get_kid : string -> t -> Key.t option
val of_string : string -> t option
