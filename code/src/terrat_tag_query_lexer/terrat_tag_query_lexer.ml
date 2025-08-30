exception Premature_end_of_string of string
exception Unexpected_symbol of string

module T = Terrat_tag_query_parser

let identifier = [%sedlex.regexp? Plus (Compl (Chars " '\"\t()"))]
let string_run = [%sedlex.regexp? Plus (Compl (Chars "'\"\\"))]

let rec string stop b buf =
  match%sedlex buf with
  | string_run ->
      Buffer.add_string b (Sedlexing.Utf8.lexeme buf);
      string stop b buf
  | '\\', any ->
      Buffer.add_char b (String.get (Sedlexing.Utf8.lexeme buf) 1);
      string stop b buf
  | Chars "'\"" -> (
      match Sedlexing.Utf8.lexeme buf with
      | "\"" when stop = '"' -> T.STRING (Buffer.contents b)
      | "'" when stop = '\'' -> T.STRING (Buffer.contents b)
      | s ->
          Buffer.add_string b s;
          string stop b buf)
  | _ -> raise (Premature_end_of_string (Buffer.contents b))

let rec token buf =
  match%sedlex buf with
  | identifier -> (
      let token = Sedlexing.Utf8.lexeme buf in
      match CCString.lowercase_ascii token with
      | "and" -> T.AND
      | "or" -> T.OR
      | "not" -> T.NOT
      | "in" -> T.IN
      | _ -> T.STRING token)
  | '(' -> T.LPAREN
  | ')' -> T.RPAREN
  | '"' ->
      let b = Buffer.create 10 in
      string '"' b buf
  | '\'' ->
      let b = Buffer.create 10 in
      string '\'' b buf
  | Plus white_space -> token buf
  | eof -> T.EOF
  | _ -> raise (Unexpected_symbol (Sedlexing.Utf8.lexeme buf))
