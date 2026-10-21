type t = Uuidm.t [@@deriving show, eq, yojson]

val v4 : unit -> Uuidm.t
val to_string : ?upper:bool -> Uuidm.t -> string
val of_string : ?pos:int -> string -> Uuidm.t option
