type err = [ `Tag_query_error of string * string ] [@@deriving show]

val of_string : string -> (Terrat_tag_query_parser_value.t option, [> err ]) result
