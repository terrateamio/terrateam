type t [@@deriving show, eq]

val make : id:Uuidm.t -> unit -> t
val id : t -> Uuidm.t
