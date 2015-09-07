type t

module Capture : sig
  type t

  val start : t -> int
  val stop  : t -> int

  val to_string  : t -> string
end

module Match : sig
  type t

  val range     : t -> (int * int)
  val to_string : t -> string
  val captures  : t -> Capture.t list
end

val of_string : string -> t option

val find : ?start:int -> string -> t -> (int * int) option

val mtch : ?start:int -> string -> t -> Match.t option

val substitute :
  ?start:int ->
  s:string ->
  r:(Match.t -> string) ->
  t ->
  string option

val rep_str : string -> Match.t -> string
