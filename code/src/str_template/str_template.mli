type err = [ `Missing_var_err of string ] [@@deriving show]

(** Given a string which reference variables of the from ${NAME}, replace them
    with the value from the given map.  Replacement can be escaped using [$],
    for example $${NAME} is the literal string ${NAME} *)
val apply : (string -> string option) -> string -> (string, [> err ]) result
