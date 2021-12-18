type t

val of_list : string list -> t
val to_list : t -> string list

(** Converts a string representing space-separated list of tags into a query *)
val of_string : string -> t

val to_string : t -> string
val match_ : query:t -> t -> bool
