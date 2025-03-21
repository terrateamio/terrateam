module Ctx = struct
  type t = {
    dirspace : Terrat_dirspace.t;
    working_dirspace : Terrat_dirspace.t option;
  }

  let make ?working_dirspace ~dirspace () = { dirspace; working_dirspace }
end

module Q = struct
  type t =
    | Or of (t * t)
    | And of (t * t)
    | Tag of string
    | Dir_glob of (string * ((string -> bool)[@opaque]))
    | Not of t
    | Any
  [@@deriving show]
end

type t = {
  s : string;
  q : Q.t;
}
[@@deriving show]

let equal { s = s1; _ } { s = s2; _ } = CCString.equal s1 s2
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

let rec process_dot_dot fname =
  match CCString.Split.left ~by:"/../" fname with
  | Some (l, r) -> (
      match CCString.Split.right ~by:"/" l with
      | Some (l', _) -> process_dot_dot (l' ^ "/" ^ r)
      | None -> process_dot_dot r)
  | None -> fname

let test_relative_dir ctx relative_dir =
  match ctx.Ctx.working_dirspace with
  | Some working_dirspace ->
      CCString.equal
        ctx.Ctx.dirspace.Terrat_dirspace.dir
        (process_dot_dot (Filename.concat working_dirspace.Terrat_dirspace.dir relative_dir))
  | None -> false

let rec match' ~ctx ~tag_set = function
  | Q.Any -> true
  | Q.Not t -> not (match' ~ctx ~tag_set t)
  | Q.Tag tag -> (
      match CCString.Split.left ~by:":" tag with
      | Some ("relative_dir", relative_dir) -> test_relative_dir ctx relative_dir
      | _ -> Terrat_tag_set.mem tag tag_set)
  | Q.Dir_glob (_, eq) -> eq ctx.Ctx.dirspace.Terrat_dirspace.dir
  | Q.And (l, r) -> match' ~ctx ~tag_set l && match' ~ctx ~tag_set r
  | Q.Or (l, r) -> match' ~ctx ~tag_set l || match' ~ctx ~tag_set r

let match_ ~ctx ~tag_set t = match' ~ctx ~tag_set t.q

let rec of_ast =
  let module T = Terrat_tag_query_parser_value in
  function
  | T.In_dir glob_str ->
      let glob = Path_glob.Glob.parse (Printf.sprintf "<**/%s/**>" (escape_glob glob_str)) in
      Q.Dir_glob (glob_str, Path_glob.Glob.eval glob)
  | T.Tag q when CCString.starts_with ~prefix:dir_in_prefix q ->
      let glob_str = CCString.drop dir_in_prefix_len q in
      let glob = Path_glob.Glob.parse (Printf.sprintf "<**/%s/**>" (escape_glob glob_str)) in
      Q.Dir_glob (glob_str, Path_glob.Glob.eval glob)
  | T.Tag tag -> Q.Tag tag
  | T.And (l, r) -> Q.And (of_ast l, of_ast r)
  | T.Or (l, r) -> Q.Or (of_ast l, of_ast r)
  | T.Not e -> Q.Not (of_ast e)

let of_string s =
  match Terrat_tag_query_ast.of_string s with
  | Ok (Some ast) -> Ok { q = of_ast ast; s }
  | Ok None -> Ok { q = Q.Any; s }
  | Error _ as err -> err

let to_string t = t.s
let any = { q = Q.Any; s = "" }
