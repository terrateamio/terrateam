type t [@@deriving show]

val of_string : string -> t
val to_string : t -> string
val match_ : t -> Terrat_tag_set.t -> bool
