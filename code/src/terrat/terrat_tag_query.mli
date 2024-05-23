type t [@@deriving show, eq]

val of_string : string -> (t, [> Terrat_tag_query_ast.err ]) result
val to_string : t -> string
val match_ : tag_set:Terrat_tag_set.t -> dirspace:Terrat_dirspace.t -> t -> bool

(** A pre-defined matcher that matches anything, equivalent to [of_string ""] *)
val any : t
