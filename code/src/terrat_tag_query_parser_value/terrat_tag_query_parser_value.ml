exception In_dir_tag_error of string

type t =
  | Tag of string
  | Or of t * t
  | And of t * t
  | Not of t
  | In_dir of string

let parse_in s = function
  | "dir" -> In_dir s
  | s -> raise (In_dir_tag_error s)
