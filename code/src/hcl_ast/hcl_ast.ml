type pos = {
  lnum : int;
  offset : int;
}
[@@deriving show]

type err = [ `Error of pos option * string * string ] [@@deriving show]
type t = Hcl_parser_value.t list [@@deriving show, eq, yojson]

let state checkpoint =
  let module I = Hcl_parser.MenhirInterpreter in
  let module S = MenhirLib.General in
  match I.top checkpoint with
  | None -> 0
  | Some (I.Element (s, _, _, _)) -> I.number s

let position checkpoint =
  let module I = Hcl_parser.MenhirInterpreter in
  let module S = MenhirLib.General in
  match I.top checkpoint with
  | None -> None
  | Some (I.Element (_, _, { Lexing.pos_lnum; pos_bol; _ }, _)) ->
      Some { lnum = pos_lnum; offset = pos_bol }

let rec loop next_token lexbuf checkpoint =
  let module I = Hcl_parser.MenhirInterpreter in
  match checkpoint with
  | I.InputNeeded _ ->
      let token = next_token () in
      let checkpoint = I.offer checkpoint token in
      loop next_token lexbuf checkpoint
  | I.Shifting (_, _, _) | I.AboutToReduce (_, _) ->
      let checkpoint = I.resume checkpoint in
      loop next_token lexbuf checkpoint
  | I.HandlingError env ->
      Error
        (try (position env, Hcl_parser_errors.message (state env))
         with Not_found -> (position env, CCInt.to_string (state env)))
  | I.Accepted ast -> Ok ast
  | I.Rejected -> assert false

let of_string s =
  (* Guarantee there is a new line at the end of the file.  The HCL spec
     requires a new line after a block but looks like it will accept files that do
     not have a new line. *)
  let lexbuf = Sedlexing.Utf8.from_string (s ^ "\n") in
  let lexer = Sedlexing.with_tokenizer Hcl_lexer.token lexbuf in
  match
    loop lexer lexbuf (Hcl_parser.Incremental.main (fst @@ Sedlexing.lexing_positions lexbuf))
  with
  | Ok r -> Ok r
  | Error (pos, err) -> Error (`Error (pos, s, CCString.trim err))
