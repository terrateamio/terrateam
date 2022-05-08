module Token = struct
  type token =
    | Left_bracket
    | Right_bracket
    | String of string
    | Equal
  [@@deriving show]

  type t = token list [@@deriving show]
end

(* Token builder. *)
module Tb : sig
  type t

  val create : unit -> t
  val add : Token.token -> t -> t
  val add_l : Token.t -> t -> t
  val build : t -> Token.t
end = struct
  type t = Token.t

  let create () = []
  let add v t = v :: t
  let add_l vs t = List.rev vs @ t
  let build t = List.rev t
end

type err =
  [ `Premature_eof
  | `Expected_section_header of int
  | `Syntax of int
  ]
[@@deriving show]

exception Tokenize_error of err

open Token

let name =
  [%sedlex.regexp? ('a' .. 'z' | 'A' .. 'Z'), Star ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-')]

let section_name =
  [%sedlex.regexp?
    ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9'), Star ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' | '.')]

let subsection_name = [%sedlex.regexp? Plus (Sub (any, "\""))]

let rec token ln bldr buf =
  match%sedlex buf with
  | "\n" -> token (ln + 1) bldr buf
  | Plus white_space -> token ln bldr buf
  | "#" -> comment ln bldr buf
  | ";" -> comment ln bldr buf
  | "[" -> section_header ln (Tb.add Left_bracket bldr) buf
  | name ->
      let name = Sedlexing.Utf8.lexeme buf in
      assignment ln (Tb.add (String name) bldr) buf
  | eof -> Tb.build bldr
  | _ -> assert false

and section_header ln bldr buf =
  match%sedlex buf with
  | section_name ->
      let name = Sedlexing.Utf8.lexeme buf in
      maybe_subsection_header ln (Tb.add (String name) bldr) buf
  | any -> raise (Tokenize_error (`Expected_section_header ln))
  | eof -> raise (Tokenize_error `Premature_eof)
  | _ -> assert false

and maybe_subsection_header ln bldr buf =
  match%sedlex buf with
  | Plus white_space -> maybe_subsection_header ln bldr buf
  | "\"" -> subsection_header ln bldr buf
  | "]" -> token ln (Tb.add Right_bracket bldr) buf
  | _ -> assert false

and end_section_header ln bldr buf =
  match%sedlex buf with
  | "]" -> token ln (Tb.add Right_bracket bldr) buf
  | any -> raise (Tokenize_error (`Expected_section_header ln))
  | eof -> raise (Tokenize_error `Premature_eof)
  | _ -> assert false

and subsection_header ln bldr buf =
  match%sedlex buf with
  | subsection_name ->
      let name = Sedlexing.Utf8.lexeme buf in
      end_subsection_header ln (Tb.add (String name) bldr) buf
  | any -> raise (Tokenize_error (`Expected_section_header ln))
  | eof -> raise (Tokenize_error `Premature_eof)
  | _ -> assert false

and end_subsection_header ln bldr buf =
  match%sedlex buf with
  | "\"" -> end_section_header ln bldr buf
  | _ -> raise (Tokenize_error (`Expected_section_header ln))

and assignment ln bldr buf =
  match%sedlex buf with
  | Star white_space, "=" ->
      let b = Buffer.create 10 in
      value b ln (Tb.add Equal bldr) buf
  | Star (Sub (white_space, "\n")) -> token ln bldr buf
  | eof -> raise (Tokenize_error `Premature_eof)
  | _ -> raise (Tokenize_error (`Syntax ln))

and value b ln bldr buf =
  match%sedlex buf with
  | "\"" ->
      Buffer.add_char b '"';
      value_in_quotes b ln bldr buf
  | "\\\n" -> value_in_quotes b (ln + 1) bldr buf
  | "\n" -> token ln (Tb.add (String (Buffer.contents b)) bldr) buf
  | "#" | ";" -> comment ln (Tb.add (String (Buffer.contents b)) bldr) buf
  | any ->
      Buffer.add_string b (Sedlexing.Utf8.lexeme buf);
      value b ln bldr buf
  | eof -> Tb.build (Tb.add (String (Buffer.contents b)) bldr)
  | _ -> assert false

and value_in_quotes b ln bldr buf =
  match%sedlex buf with
  | Star (Sub (any, ("\\" | "\"" | "\n"))) ->
      Buffer.add_string b (Sedlexing.Utf8.lexeme buf);
      value_in_quotes b ln bldr buf
  | "\\", any ->
      Buffer.add_string b (Sedlexing.Utf8.lexeme buf);
      value_in_quotes b ln bldr buf
  | "\"" ->
      Buffer.add_char b '"';
      value b ln bldr buf
  | "\n" -> raise (Tokenize_error (`Syntax ln))
  | _ -> assert false

and comment ln bldr buf =
  match%sedlex buf with
  | Star (Sub (any, "\n")) -> token ln bldr buf
  | eof -> Tb.build bldr
  | _ -> assert false

let tokenize s =
  try Ok (token 1 (Tb.create ()) s) with Tokenize_error err -> Error (err : err :> [> err ])
