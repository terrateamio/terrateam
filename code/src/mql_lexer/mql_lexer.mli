(** Raised on any input the lexer cannot turn into a token, including a [$name] variable when
    [variables] is [false]. {!Mql.Ast.of_string} catches this and turns it into an error. *)
exception Lex_err of string

(** Produce the next token. [variables] admits the [$name] named-variable syntax understood by
    {!Pgsql_io.Typed_sql}; when [false], encountering one raises {!Lex_err}.

    PostgreSQL's two comment forms are skipped rather than tokenised: [--] to end of line, and
    nesting [/* ... */] blocks. Because they are dropped here they never reach the parser and are
    not reproduced by {!Mql.Ast.to_string}. An unterminated block comment raises {!Lex_err}. *)
val token : variables:bool -> Sedlexing.lexbuf -> Mql_parser.token
