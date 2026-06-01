module T = Mql_parser

let digit = [%sedlex.regexp? '0' .. '9']
let exp = [%sedlex.regexp? 'e' | 'E']
let plus_minus = [%sedlex.regexp? '+' | '-']
let hex_digit = [%sedlex.regexp? '0' .. '9' | 'a' .. 'f' | 'A' .. 'F']
let identifier_start = [%sedlex.regexp? 'a' .. 'z' | 'A' .. 'Z' | '_']
let identifier_rest = [%sedlex.regexp? 'a' .. 'z' | 'A' .. 'Z' | '_' | '0' .. '9']
let lexeme buf = Sedlexing.Utf8.lexeme buf

let rec token buf =
  match%sedlex buf with
  | "select" | "SELECT" -> T.SELECT
  | "from" | "FROM" -> T.FROM
  | "inner" | "INNER" -> T.INNER
  | "left" | "LEFT" -> T.LEFT
  | "right" | "RIGHT" -> T.RIGHT
  | "join" | "JOIN" -> T.JOIN
  | "where" | "WHERE" -> T.WHERE
  | "in" | "IN" -> T.IN
  | "like" | "LIKE" -> T.LIKE
  | "ilike" | "ILIKE" -> T.ILIKE
  | "is not" | "IS not" | "is NOT" | "IS NOT" -> T.IS_NOT
  | "is distinct from"
  | "IS distinct from"
  | "IS DISTINCT from"
  | "IS DISTINCT FROM"
  | "is DISTINCT FROM"
  | "is distinct FROM" -> T.IS_DISTINCT_FROM
  | "is not distinct from"
  | "IS not distinct from"
  | "IS NOT distinct from"
  | "IS NOTDISTINCT from"
  | "IS NOT DISTINCT FROM"
  | "is NOT DISTINCT FROM"
  | "is not DISTINCT FROM"
  | "is not distinct FROM" -> T.IS_NOT_DISTINCT_FROM
  | "is" | "IS" -> T.IS
  | "not" | "NOT" -> T.NOT
  | "as" | "AS" -> T.AS
  | "with" | "WITH" -> T.WITH
  | "materialized" | "MATERIALIZED" -> T.MATERIALIZED
  | "group" | "GROUP" -> T.GROUP
  | "having" | "HAVING" -> T.HAVING
  | "order" | "ORDER" -> T.ORDER
  | "by" | "BY" -> T.BY
  | "on" | "ON" -> T.ON
  | "asc" | "ASC" -> T.ASC
  | "desc" | "DESC" -> T.DESC
  | "limit" | "LIMIT" -> T.LIMIT
  | "and" | "AND" -> T.AND
  | "or" | "OR" -> T.OR
  | "count" | "COUNT" -> T.COUNT
  | "true" | "TRUE" -> T.TRUE
  | "false" | "FALSE" -> T.FALSE
  | "null" | "NULL" -> T.NULL
  | "unnest" | "UNNEST" -> T.UNNEST
  | "exists" | "EXISTS" -> T.EXISTS
  | "union" | "UNION" -> T.UNION
  | "all" | "ALL" -> T.ALL
  | "->" -> T.JSON_VAL
  | "->>" -> T.JSON_TEXT
  | '=' -> T.EQUAL
  | "<>" -> T.NOT_EQUAL
  | '<' -> T.LT
  | "<=" -> T.LTE
  | '>' -> T.GT
  | ">=" -> T.GTE
  | "@>" -> T.JSON_SUBSET
  | "#>>" -> T.JSON_OBJ_QUERY
  | '[' -> T.LBRACKET
  | ']' -> T.RBRACKET
  | '(' -> T.LPAREN
  | ')' -> T.RPAREN
  | '+' -> T.PLUS
  | '-' -> T.MINUS
  | '/' -> T.DIV
  | '*' -> T.STAR
  | ',' -> T.COMMA
  | "||" -> T.DOUBLE_PIPE
  | "::" -> T.DOUBLE_COLON
  | '.' -> T.DOT
  | "'" -> parse_string_literal buf (Buffer.create 20)
  | Plus digit, exp, Opt plus_minus, Plus digit -> T.FLOAT (float_of_string (lexeme buf))
  | Plus digit, '.', Plus digit, exp, Opt plus_minus, Plus digit ->
      T.FLOAT (float_of_string (lexeme buf))
  | Plus digit, '.', Plus digit -> T.FLOAT (float_of_string (lexeme buf))
  | Plus digit -> T.INTEGER (int_of_string (lexeme buf))
  | identifier_start, Star identifier_rest -> T.IDENTIFIER (lexeme buf)
  | Plus white_space -> token buf
  | eof -> T.EOF
  | any -> failwith (Printf.sprintf "Unexpected character: %S" (lexeme buf))
  | _ -> failwith ("Unexpected character: " ^ lexeme buf)

and parse_string_literal buf acc =
  match%sedlex buf with
  | "''" ->
      Buffer.add_char acc '\'';
      parse_string_literal buf acc
  | "'" -> T.STRING (Buffer.contents acc)
  | any ->
      Buffer.add_string acc (lexeme buf);
      parse_string_literal buf acc
  | _ -> failwith "Unexpected character in string literal"
