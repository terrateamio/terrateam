type err = [ `Tag_query_error of string * string ] [@@deriving show]

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
  | Ok r -> Ok r
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
