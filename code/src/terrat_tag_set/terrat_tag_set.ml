type t_printer = string list [@@deriving show]

type t = (Sln_set.String.t[@printer fun fmt v -> pp_t_printer fmt (Sln_set.String.to_list v)])
[@@deriving show]

let of_list = Sln_set.String.of_list
let to_list = Sln_set.String.to_list

let of_string =
  CCFun.(CCString.split_on_char ' ' %> CCList.filter (CCString.is_empty %> not) %> of_list)

let to_string t = t |> Sln_set.String.to_list |> CCString.concat " "
let match_ ~query t = Sln_set.String.subset query t
let mem = Sln_set.String.mem
