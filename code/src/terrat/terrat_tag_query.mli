type t [@@deriving show]

val of_string : string -> t
val to_string : t -> string
val match_ : tag_set:Terrat_tag_set.t -> dirspace:Terrat_change.Dirspace.t -> t -> bool
