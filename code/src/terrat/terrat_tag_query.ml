type err = [ `Tag_query_error of string * string ] [@@deriving show]

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

let rec match' ~tag_set ~dirspace = function
  | Q.Any -> true
  | Q.Not t -> not (match' ~tag_set ~dirspace t)
  | Q.Tag tag -> Terrat_tag_set.mem tag tag_set
  | Q.Dir_glob (_, eq) -> eq dirspace.Terrat_change.Dirspace.dir
  | Q.And (l, r) -> match' ~tag_set ~dirspace l && match' ~tag_set ~dirspace r
  | Q.Or (l, r) -> match' ~tag_set ~dirspace l || match' ~tag_set ~dirspace r

let match_ ~tag_set ~dirspace t = match' ~tag_set ~dirspace t.q

let rec of_ast =
  let module T = Terrat_tag_query_parser_value in
  function
  | T.In_dir glob_str ->
      let glob = Path_glob.Glob.parse (Printf.sprintf "<**/%s/**>" (escape_glob glob_str)) in
      Q.Dir_glob (glob_str, Path_glob.Glob.eval glob)
  | T.Tag tag -> Q.Tag tag
  | T.And (l, r) -> Q.And (of_ast l, of_ast r)
  | T.Or (l, r) -> Q.Or (of_ast l, of_ast r)
  | T.Not e -> Q.Not (of_ast e)

let state checkpoint =
  let module I = Terrat_tag_query_parser.MenhirInterpreter in
  let module S = MenhirLib.General in
  match I.top checkpoint with
  | None -> 0
  | Some (I.Element (s, _, _, _)) -> I.number s

let rec loop next_token lexbuf checkpoint =
  let module I = Terrat_tag_query_parser.MenhirInterpreter in
  match checkpoint with
  | I.InputNeeded _ ->
      let token = next_token () in
      let checkpoint = I.offer checkpoint token in
      loop next_token lexbuf checkpoint
  | I.Shifting (_, _, _) | I.AboutToReduce (_, _) ->
      let checkpoint = I.resume checkpoint in
      loop next_token lexbuf checkpoint
  | I.HandlingError env -> Error (Terrat_tag_query_parser_errors.message (state env))
  | I.Accepted ast -> Ok ast
  | I.Rejected -> assert false

let of_string s =
  let lexbuf = Sedlexing.Utf8.from_string s in
  let lexer = Sedlexing.with_tokenizer Terrat_tag_query_lexer.token lexbuf in
  match
    loop
      lexer
      lexbuf
      (Terrat_tag_query_parser.Incremental.start (fst @@ Sedlexing.lexing_positions lexbuf))
  with
  | Ok (Some ast) -> Ok { q = of_ast ast; s }
  | Ok None -> Ok { q = Q.Any; s }
  | Error err -> Error (`Tag_query_error (s, CCString.trim err))
  | exception Terrat_tag_query_lexer.Premature_end_of_string err ->
      Error (`Tag_query_error (s, Printf.sprintf "Premature end of string in `%s`." err))
  | exception Terrat_tag_query_lexer.Unexpected_symbol err ->
      Error (`Tag_query_error (s, Printf.sprintf "Unexpected symbol `%s`." err))
  | exception Terrat_tag_query_parser_value.In_dir_tag_error err ->
      Error
        (`Tag_query_error
          ( s,
            Printf.sprintf
              "The `in` operator only accepts `dir` on the right hand side, got `%s`."
              err ))

let to_string t = t.s
let any = { q = Q.Any; s = "" }
