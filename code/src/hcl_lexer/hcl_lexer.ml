module T = Hcl_parser

let digit = [%sedlex.regexp? '0' .. '9']
let exp = [%sedlex.regexp? 'e' | 'E']
let plus_minus = [%sedlex.regexp? '+' | '-']
let hex_digit = [%sedlex.regexp? '0' .. '9' | 'a' .. 'f' | 'A' .. 'F']
let whitespace_not_newline = [%sedlex.regexp? ' ' | '\t' | '\r']
let whitespace = [%sedlex.regexp? whitespace_not_newline | '\n']
let identifier_start = [%sedlex.regexp? 'a' .. 'z' | 'A' .. 'Z' | '_']
let identifier_rest = [%sedlex.regexp? 'a' .. 'z' | 'A' .. 'Z' | '_' | '-' | '0' .. '9']
let lexeme buf = Sedlexing.Utf8.lexeme buf

let rec token buf =
  match%sedlex buf with
  | '\n' -> T.NEWLINE
  | Plus whitespace_not_newline -> token buf (* Skip whitespace *)
  | '#' | "//" -> ignore_line_comment buf
  | "/*" -> ignore_multiline_comment buf
  | "<<" -> heredoc_start buf
  | "..." -> T.ELLIPSIS
  | '+' -> T.PLUS
  | "&&" -> T.LOG_AND
  | "==" -> T.IS_EQUAL
  | '<' -> T.LESS_THAN
  | ':' -> T.COLON
  | '{' -> T.LBRACE
  | '[' -> T.LBRACKET
  | '(' -> T.LPAREN
  | '-' -> T.MINUS
  | "||" -> T.LOG_OR
  | "!=" -> T.NOT_EQUAL
  | '>' -> T.GREATER_THAN
  | '?' -> T.QUESTION_MARK
  | '}' -> T.RBRACE
  | ']' -> T.RBRACKET
  | ')' -> T.RPAREN
  | '*' -> T.MULT
  | '!' -> T.NOT
  | "<=" -> T.LESS_THAN_EQUAL
  | '=' -> T.EQUAL
  | '.' -> T.DOT
  | '/' -> T.DIV
  | ">=" -> T.GREATER_THAN_EQUAL
  | "=>" -> T.FAT_ARROW
  | ',' -> T.COMMA
  | '%' -> T.PERCENT
  | "true" -> T.TRUE
  | "false" -> T.FALSE
  | "null" -> T.NULL
  | "for" -> T.FOR
  | "in" -> T.IN
  | "if" -> T.IF
  | '"' -> parse_string_literal buf (Buffer.create 20)
  | Plus digit, exp, Opt plus_minus, Plus digit -> T.FLOAT (float_of_string (lexeme buf))
  | Plus digit, '.', Plus digit, exp, Opt plus_minus, Plus digit ->
      T.FLOAT (float_of_string (lexeme buf))
  | Plus digit, '.', Plus digit -> T.FLOAT (float_of_string (lexeme buf))
  | Plus digit -> T.INTEGER (int_of_string (lexeme buf))
  | identifier_start, Star identifier_rest -> T.IDENTIFIER (lexeme buf)
  | eof -> T.EOF
  | _ -> failwith "Unexpected character"

and parse_string_literal buf acc =
  match%sedlex buf with
  | '"' -> T.STRING (Buffer.contents acc)
  | "$${" ->
      Buffer.add_string acc "${";
      parse_string_literal buf acc
  | "%%{" ->
      Buffer.add_string acc "%{";
      parse_string_literal buf acc
  | "${" ->
      Buffer.add_string acc "${";
      parse_template buf acc;
      parse_string_literal buf acc
  | "%{" ->
      Buffer.add_string acc "%{";
      parse_template buf acc;
      parse_string_literal buf acc
  | '\\' -> parse_string_literal_escape buf acc
  | any ->
      Buffer.add_string acc (lexeme buf);
      parse_string_literal buf acc
  | _ -> failwith "Unexpected character in string literal"

and parse_string_literal_escape buf acc =
  match%sedlex buf with
  | any ->
      Buffer.add_string acc (lexeme buf);
      parse_string_literal buf acc
  | _ -> failwith "Unexpected character in string literal escape"

and parse_template buf acc =
  match%sedlex buf with
  | '{' ->
      Buffer.add_string acc (lexeme buf);
      parse_template buf acc;
      parse_template buf acc
  | '}' -> Buffer.add_string acc (lexeme buf)
  | any ->
      Buffer.add_string acc (lexeme buf);
      parse_template buf acc
  | _ -> failwith "Unexpected template string"

and ignore_line_comment buf =
  match%sedlex buf with
  | Star (Compl '\n') -> ignore_line_comment buf
  | '\n' -> T.NEWLINE
  | eof -> T.EOF
  | _ -> failwith "Unexpected end"

and ignore_multiline_comment buf =
  match%sedlex buf with
  | "*/" -> token buf
  | any -> ignore_multiline_comment buf
  | eof -> failwith "Unexpected EOF in multiline comment"
  | _ -> assert false

and heredoc_start buf =
  match%sedlex buf with
  | '-' -> heredoc_start buf
  | identifier_start, Star identifier_rest -> heredoc_rest (lexeme buf) buf (Buffer.create 50)
  | _ -> failwith "heredoc_start"

and heredoc_rest id buf acc =
  match%sedlex buf with
  | eof -> failwith "heredoc_rest eof"
  | '\n' ->
      Buffer.add_char acc '\n';
      heredoc_rest id buf acc
  | Plus (Compl '\n') ->
      let line = lexeme buf in
      if CCString.equal (CCString.trim line) id then T.HEREDOC (Buffer.contents acc)
      else (
        Buffer.add_string acc line;
        Buffer.add_char acc '\n';
        heredoc_rest id buf acc)
  | _ -> failwith "heredoc_rest"
