%token <string> STRING
%token LPAREN RPAREN
%token AND OR
%token NOT IN
%left OR
%left AND
%token EOF

%{
    open Terrat_tag_query_parser_value
%}

%start <Terrat_tag_query_parser_value.t option> start

%on_error_reduce expr

%%

start:
  | EOF
    { None }
  | e = expr; EOF
    { Some e }
;

expr:
  | s1 = STRING; IN; s2 = STRING
    { parse_in s1 s2 }
  | tag = STRING
    { Tag tag }
  | LPAREN; e = expr; RPAREN
    { e }
  | e1 = expr; OR; e2 = expr
    { Or (e1, e2) }
  | e1 = expr; AND; e2 = expr
    { And (e1, e2) }
  | e1 = expr; e2 = expr
    { And (e1, e2) }
  | NOT; tag = STRING
    { Not (Tag tag) }
  | NOT; LPAREN; e = expr; RPAREN
    { Not e }
;
