type t [@@deriving show]
type err = [ `Tag_query_error of string * string ] [@@deriving show]

val of_string : string -> (t, [> err ]) result
val to_string : t -> string
val match_ : tag_set:Terrat_tag_set.t -> dirspace:Terrat_change.Dirspace.t -> t -> bool

(** A pre-defined matcher that matches anything, equivalent to [of_string ""] *)
val any : t
