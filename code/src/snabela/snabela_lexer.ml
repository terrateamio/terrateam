module Token = struct
  type token =
    | Escaped_at
    | At of int
    | List
    | Test
    | Neg_test
    | Left_trim
    | Right_trim
    | Key of string
    | Transformer of string
    | String of string
    | End_section
    | Comment
    | Exists
  [@@deriving show, eq]

  type t = token list [@@deriving show, eq]
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
  | `Invalid_replacement of int
  | `Invalid_transformer of int
  ]
[@@deriving show, eq]

exception Tokenize_error of err

open Token

let key =
  [%sedlex.regexp?
    ('a' .. 'z' | 'A' .. 'Z'), Star ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '=')]

let rec token ln bldr buf =
  match%sedlex buf with
  | "@@" -> token ln (Tb.add Escaped_at bldr) buf
  | "@-%" -> comment ln (Tb.add_l [ At ln; Left_trim; Comment ] bldr) buf
  | "@%" -> comment ln (Tb.add_l [ At ln; Comment ] bldr) buf
  | "@-#?" -> replacement ln (Tb.add_l [ At ln; Left_trim; List; Test ] bldr) buf
  | "@-#!" -> replacement ln (Tb.add_l [ At ln; Left_trim; List; Neg_test ] bldr) buf
  | "@-#" -> replacement ln (Tb.add_l [ At ln; Left_trim; List ] bldr) buf
  | "@-^!" -> replacement ln (Tb.add_l [ At ln; Left_trim; Exists; Neg_test ] bldr) buf
  | "@-^" -> replacement ln (Tb.add_l [ At ln; Left_trim; Exists; Test ] bldr) buf
  | "@#?" -> replacement ln (Tb.add_l [ At ln; List; Test ] bldr) buf
  | "@#!" -> replacement ln (Tb.add_l [ At ln; List; Neg_test ] bldr) buf
  | "@^!" -> replacement ln (Tb.add_l [ At ln; Exists; Neg_test ] bldr) buf
  | "@^" -> replacement ln (Tb.add_l [ At ln; Exists; Test ] bldr) buf
  | "@#" -> replacement ln (Tb.add_l [ At ln; List ] bldr) buf
  | "@-?" -> replacement ln (Tb.add_l [ At ln; Left_trim; Test ] bldr) buf
  | "@-!" -> replacement ln (Tb.add_l [ At ln; Left_trim; Neg_test ] bldr) buf
  | "@?" -> replacement ln (Tb.add_l [ At ln; Test ] bldr) buf
  | "@!" -> replacement ln (Tb.add_l [ At ln; Neg_test ] bldr) buf
  | "@-" -> replacement ln (Tb.add_l [ At ln; Left_trim ] bldr) buf
  | "@" -> replacement ln (Tb.add (At ln) bldr) buf
  | Star (Sub (any, "@")) ->
      let str = Sedlexing.Utf8.lexeme buf in
      let n = List.length (CCString.find_all_l ~sub:"\n" str) in
      token (ln + n) (Tb.add (String str) bldr) buf
  | eof -> Tb.build bldr
  | _ -> assert false

and replacement ln bldr buf =
  match%sedlex buf with
  | "\n" -> replacement (ln + 1) bldr buf
  | white_space -> replacement ln bldr buf
  | "/", key ->
      let key = Sedlexing.Utf8.sub_lexeme buf 1 (Sedlexing.lexeme_length buf - 1) in
      replacement_close ln (Tb.add_l [ End_section; Key key ] bldr) buf
  | "@" -> token ln (Tb.add (At ln) bldr) buf
  | key ->
      let key = Sedlexing.Utf8.lexeme buf in
      transformer ln (Tb.add (Key key) bldr) buf
  | _ -> raise (Tokenize_error (`Invalid_replacement ln))

and transformer ln bldr buf =
  match%sedlex buf with
  | "\n" -> transformer (ln + 1) bldr buf
  | white_space -> transformer ln bldr buf
  | "|" -> transformer_key ln bldr buf
  | eof -> raise (Tokenize_error `Premature_eof)
  | _ ->
      Sedlexing.rollback buf;
      replacement_close ln bldr buf

and transformer_key ln bldr buf =
  match%sedlex buf with
  | "\n" -> transformer_key (ln + 1) bldr buf
  | white_space -> transformer_key ln bldr buf
  | key ->
      let key = Sedlexing.Utf8.lexeme buf in
      transformer ln (Tb.add (Transformer key) bldr) buf
  | _ -> raise (Tokenize_error (`Invalid_transformer ln))

and replacement_close ln bldr buf =
  match%sedlex buf with
  | "-@" -> token ln (Tb.add_l [ Right_trim; At ln ] bldr) buf
  | "@" -> token ln (Tb.add (At ln) bldr) buf
  | _ -> raise (Tokenize_error (`Invalid_replacement ln))

and comment ln bldr buf =
  match%sedlex buf with
  | "-@" -> token ln (Tb.add_l [ Right_trim; At ln ] bldr) buf
  | "@" -> token ln (Tb.add (At ln) bldr) buf
  | '\n' -> comment (ln + 1) bldr buf
  | any -> comment ln bldr buf
  | _ -> assert false

let tokenize s =
  try Ok (token 1 (Tb.create ()) s) with Tokenize_error err -> Error (err : err :> [> err ])
