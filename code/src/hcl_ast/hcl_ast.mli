type pos = {
  lnum : int;
  offset : int;
}
[@@deriving show]

type err = [ `Error of pos option * string * string ] [@@deriving show]
type t = Hcl_parser_value.t list [@@deriving show, eq, yojson]

val of_string : string -> (t, [> err ]) result
