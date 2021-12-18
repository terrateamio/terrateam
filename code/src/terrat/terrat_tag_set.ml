module String_set = CCSet.Make (CCString)

type t = String_set.t

let of_list = String_set.of_list
let to_list = String_set.to_list

let of_string =
  CCFun.(CCString.split_on_char ' ' %> CCList.filter (CCString.is_empty %> not) %> of_list)

let to_string t = t |> String_set.to_list |> CCString.concat " "
let match_ ~query t = String_set.subset query t
