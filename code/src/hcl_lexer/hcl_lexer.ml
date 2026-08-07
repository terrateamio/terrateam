module T = Hcl_parser

exception
  Error of {
    msg : string;
    lexeme : string;
  }

let digit = [%sedlex.regexp? '0' .. '9']
let exp = [%sedlex.regexp? 'e' | 'E']
let plus_minus = [%sedlex.regexp? '+' | '-']
let hex_digit = [%sedlex.regexp? '0' .. '9' | 'a' .. 'f' | 'A' .. 'F']

(* [\r] deliberately excluded: hclsyntax rejects a standalone [\r] anywhere
   with "Invalid character; This character is not used within the language."
   Only the [\r\n] pair is a valid line ending, and that's handled by the
   dedicated NEWLINE arm in [token]. *)
let whitespace_not_newline = [%sedlex.regexp? ' ' | '\t']
let whitespace = [%sedlex.regexp? whitespace_not_newline | '\n']

(* HCL2 spec allows Unicode letters in identifiers. Sedlex provides built-in
   Unicode category matchers: lu=uppercase, ll=lowercase, lt=titlecase,
   lm=modifier, lo=other letter, nl=letter number, mn=nonspacing mark,
   mc=spacing mark, nd=decimal digit, pc=connector punctuation. *)
let identifier_start = [%sedlex.regexp? 'a' .. 'z' | 'A' .. 'Z' | '_' | lu | ll | lt | lm | lo | nl]

let identifier_rest =
  [%sedlex.regexp?
    ( 'a' .. 'z'
    | 'A' .. 'Z'
    | '_' | '-'
    | '0' .. '9'
    | lu | ll | lt | lm | lo | nl | mn | mc | nd | pc )]

let lexeme buf = Sedlexing.Utf8.lexeme buf
let error msg buf = raise (Error { msg; lexeme = lexeme buf })

(* The [<<-] (flush) common-leading-whitespace strip is NOT done here: it has to
   see the template structure, both so a newline inside a [${...}] / [%{...}] span
   does not participate and so it runs after the [~] strip markers, which decide
   what is still indentation. The lexer keeps the raw body and only records
   whether the marker was [<<-] (via the [HEREDOC] token's [strip] flag →
   [Expr.Heredoc']); the flush is applied in [Hcl_ast_template.promote_heredoc],
   by [flush_heredoc_parts] once the body is parsed, or by [flush_heredoc_body]
   when the body has no template syntax at all. *)

let rec token buf =
  match%sedlex buf with
  | '\n' | "\r\n" -> T.NEWLINE
  | Plus whitespace_not_newline -> token buf (* Skip whitespace *)
  | '#' | "//" -> ignore_line_comment buf
  | "/*" -> ignore_multiline_comment buf
  | "<<" -> heredoc_start buf
  | "..." -> T.ELLIPSIS
  | '+' -> T.PLUS
  | "&&" -> T.LOG_AND
  | "==" -> T.IS_EQUAL
  | '<' -> T.LESS_THAN
  | "::" -> T.DOUBLE_COLON
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
  | Plus digit, exp, Opt plus_minus, Plus digit ->
      let s = lexeme buf in
      T.FLOAT (s, float_of_string s)
  | Plus digit, '.', Plus digit, exp, Opt plus_minus, Plus digit ->
      let s = lexeme buf in
      T.FLOAT (s, float_of_string s)
  (* Reject multi-dot numeric literals like [1.2.3] at lex time (shim
     behaviour: hclsyntax's Ragel scanner greedily consumes the run and
     [cty.ParseNumberVal] fails). If we instead let [1.2.3] fall through,
     sedlex's longest-match would take [1.2] as a FLOAT and [.3] would
     reach the grammar as [DOT INTEGER], producing a spurious
     [Attr(Float 1.2, A_int 3)] attribute access. *)
  | Plus digit, '.', Plus digit, '.', Plus digit, Star ('.', Plus digit) ->
      error "Invalid number literal" buf
  | Plus digit, '.', Plus digit ->
      let s = lexeme buf in
      T.FLOAT (s, float_of_string s)
  | Plus digit -> (
      let s = lexeme buf in
      (* HCL allows arbitrarily large integer literals (e.g. 229781080725244020000)
         that exceed OCaml's native int range. When a literal overflows int_of_string,
         fall back to float to preserve the value rather than rejecting the file. Both
         token variants carry the raw lexeme so object keys can round-trip their
         source form. *)
      try T.INTEGER (s, int_of_string s) with Failure _ -> T.FLOAT (s, float_of_string s))
  | identifier_start, Star identifier_rest, Plus ("::", identifier_start, Star identifier_rest) ->
      (* At least one [::] segment → namespaced identifier. The grammar
         requires [(] after this token (function call); standalone or
         traversal uses reject. *)
      T.NAMESPACED_IDENTIFIER (lexeme buf)
  | identifier_start, Star identifier_rest -> T.IDENTIFIER (lexeme buf)
  | eof -> T.EOF
  (* U+FEFF mid-file is an [Invalid character] per hclsyntax. A leading BOM
     is legitimate on UTF-8 [.tf] files but must appear at offset 0 — the
     caller in [Hcl_ast.Menhir.of_string] strips it there, so by the time
     the lexer sees any [U+FEFF] it's necessarily mid-file and an error. *)
  | any -> error "Unexpected character" buf
  | _ -> error "Unexpected end of input" buf

and parse_string_literal buf acc =
  match%sedlex buf with
  | '"' -> T.STRING (Buffer.contents acc)
  | "$${" ->
      (* HCL template escape: preserve $${ verbatim so the downstream template
         parser recognizes it as an escaped ${ rather than an interpolation. *)
      Buffer.add_string acc "$${";
      parse_string_literal buf acc
  | "%%{" ->
      Buffer.add_string acc "%%{";
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
  (* Literal newlines are not allowed inside a quoted string. *)
  | '\n' -> error "Invalid multi-line string" buf
  | any ->
      Buffer.add_string acc (lexeme buf);
      parse_string_literal buf acc
  | _ -> error "Unterminated string literal" buf

and parse_string_literal_escape buf acc =
  match%sedlex buf with
  | 'n' ->
      Buffer.add_char acc '\n';
      parse_string_literal buf acc
  | 't' ->
      Buffer.add_char acc '\t';
      parse_string_literal buf acc
  | 'r' ->
      Buffer.add_char acc '\r';
      parse_string_literal buf acc
  | '"' ->
      Buffer.add_char acc '"';
      parse_string_literal buf acc
  | '\\' ->
      Buffer.add_char acc '\\';
      parse_string_literal buf acc
  | 'u', Rep (hex_digit, 4) ->
      let s = lexeme buf in
      let code = int_of_string ("0x" ^ String.sub s 1 4) in
      Buffer.add_utf_8_uchar acc (Uchar.of_int code);
      parse_string_literal buf acc
  | 'U', Rep (hex_digit, 8) ->
      let s = lexeme buf in
      let code = int_of_string ("0x" ^ String.sub s 1 8) in
      Buffer.add_utf_8_uchar acc (Uchar.of_int code);
      parse_string_literal buf acc
  (* [\u] with fewer than 4 hex digits or [\U] with fewer than 8: the
     valid-form arms above win on longest match, so this only fires when
     there aren't enough digits. *)
  | 'u' | 'U' -> error "Invalid escape sequence" buf
  | any -> error "Invalid escape sequence" buf
  | _ -> error "Unterminated string escape" buf

and parse_template buf acc =
  match%sedlex buf with
  | '{' ->
      Buffer.add_string acc (lexeme buf);
      parse_template buf acc;
      parse_template buf acc
  | '}' -> Buffer.add_string acc (lexeme buf)
  | '"' ->
      Buffer.add_string acc (lexeme buf);
      parse_template_string buf acc;
      parse_template buf acc
  | any ->
      Buffer.add_string acc (lexeme buf);
      parse_template buf acc
  | _ -> error "Unterminated template expression" buf

and parse_template_string buf acc =
  match%sedlex buf with
  | '"' -> Buffer.add_string acc (lexeme buf)
  | "${" ->
      Buffer.add_string acc (lexeme buf);
      parse_template buf acc;
      parse_template_string buf acc
  | "%{" ->
      Buffer.add_string acc (lexeme buf);
      parse_template buf acc;
      parse_template_string buf acc
  | '\\', any ->
      Buffer.add_string acc (lexeme buf);
      parse_template_string buf acc
  (* Same multi-line-string restriction as [parse_string_literal]: a literal
     newline inside a quoted string (even one nested inside [${..}]) is invalid *)
  | '\n' -> error "Invalid multi-line string" buf
  | any ->
      Buffer.add_string acc (lexeme buf);
      parse_template_string buf acc
  | _ -> error "Unterminated string in template" buf

and ignore_line_comment buf =
  match%sedlex buf with
  | Star (Compl '\n') -> ignore_line_comment buf
  | '\n' -> T.NEWLINE
  | eof -> T.EOF
  | _ -> error "Unexpected end of line comment" buf

and ignore_multiline_comment buf =
  match%sedlex buf with
  | "*/" -> token buf
  | any -> ignore_multiline_comment buf
  | eof -> error "Unterminated multiline comment" buf
  | _ -> assert false

and heredoc_start buf =
  (* Accept at most one [-] (strip-indent marker); [<<--EOF], [<<---EOF]
     etc. reject because hclsyntax only defines [<<] and [<<-]. Then
     require a newline (or [\r\n]) immediately after the marker identifier
     — trailing content on the opener line ([<<EOF extra\n]) is invalid,
     whereas the previous implementation silently folded it into the body. *)
  match%sedlex buf with
  | Opt '-', identifier_start, Star identifier_rest ->
      let full = lexeme buf in
      let flen = String.length full in
      let strip = flen > 0 && full.[0] = '-' in
      let id = if strip then String.sub full 1 (flen - 1) else full in
      heredoc_after_marker id ~strip buf (Buffer.create 50)
  | _ -> error "Invalid heredoc start" buf

and heredoc_after_marker id ~strip buf acc =
  match%sedlex buf with
  | Opt '\r', '\n' ->
      (* Keep the leading [\n] in the body to match the pre-existing
         heredoc shape ([<<EOF\nbody\nEOF] → body = "\nbody\n"). On CRLF
         input the [\r] is part of the opener line, not the body, so it's
         dropped silently. *)
      Buffer.add_char acc '\n';
      heredoc_rest id ~strip buf acc
  | _ -> error "Extra characters after heredoc marker" buf

and heredoc_rest id ~strip buf acc =
  match%sedlex buf with
  | eof -> error "Unterminated heredoc" buf
  | '\n' ->
      Buffer.add_char acc '\n';
      heredoc_rest id ~strip buf acc
  | Plus (Compl '\n') ->
      let line = lexeme buf in
      if CCString.equal (CCString.trim line) id then
        (* Emit the RAW body plus the [strip] ([<<-]) flag; the flush-heredoc
           whitespace strip runs later on the structured body (see the note on
           [strip_heredoc_indent]'s removal above). *)
        T.HEREDOC (strip, id, Buffer.contents acc)
      else (
        Buffer.add_string acc line;
        heredoc_rest id ~strip buf acc)
  | _ -> error "Unexpected end of heredoc" buf
