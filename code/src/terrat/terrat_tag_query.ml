module Q = struct
  type t =
    | Tag of string
    | Dir_glob of (string * ((string -> bool)[@opaque]))
  [@@deriving show]
end

type t = Q.t list [@@deriving show]

let dir_in_prefix = "dir~"
let dir_in_prefix_len = CCString.length dir_in_prefix

let escape_glob s =
  let b = Buffer.create (CCString.length s) in
  CCString.iter
    (function
      | ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '-' | '.' | ' ' | '/') as c ->
          Buffer.add_char b c
      | c ->
          Buffer.add_char b '\\';
          Buffer.add_char b c)
    s;
  Buffer.contents b

let[@tail_mod_cons] rec of_string' = function
  | q :: qs when CCString.(is_empty (trim q)) -> of_string' qs
  | q :: qs when CCString.starts_with ~prefix:dir_in_prefix q ->
      let glob_str = CCString.drop dir_in_prefix_len q in
      let glob = Path_glob.Glob.parse (Printf.sprintf "<**/%s/**>" (escape_glob glob_str)) in
      Q.Dir_glob (glob_str, Path_glob.Glob.eval glob) :: of_string' qs
  | q :: qs -> Q.Tag q :: of_string' qs
  | [] -> []

let[@tail_mod_cons] rec to_string' = function
  | Q.Tag tag :: ts -> tag :: to_string' ts
  | Q.Dir_glob (s, _) :: ts -> ("dir~" ^ s) :: to_string' ts
  | [] -> []

let of_string s = of_string' (s |> CCString.split_on_char ' ' |> CCList.filter (( <> ) ""))
let to_string t = CCString.concat " " (to_string' t)

let rec match_ ~tag_set ~dirspace = function
  | Q.Tag tag :: ts when Terrat_tag_set.mem tag tag_set -> match_ ~tag_set ~dirspace ts
  | Q.Dir_glob (_, eq) :: ts when eq dirspace.Terrat_change.Dirspace.dir ->
      match_ ~tag_set ~dirspace ts
  | [] -> true
  | _ -> false
