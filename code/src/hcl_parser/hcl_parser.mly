%{
  open Hcl_parser_value
%}

%token <string> IDENTIFIER
%token <string> STRING
%token <int> INTEGER
%token <float> FLOAT
%token <string> HEREDOC
%token TRUE FALSE NULL
%token LPAREN RPAREN
%token LBRACKET RBRACKET
%token LBRACE RBRACE
%token FOR IN IF
%token FAT_ARROW
%token EQUAL COMMA DOT COLON ELLIPSIS QUESTION_MARK PERCENT
%token IS_EQUAL LESS_THAN NOT_EQUAL GREATER_THAN LESS_THAN_EQUAL GREATER_THAN_EQUAL
%token PLUS MINUS MULT DIV
%token LOG_AND LOG_OR NOT
%token NEWLINE EOF

%left COLON
%left QUESTION_MARK
%left LOG_OR
%left LOG_AND
%left IS_EQUAL NOT_EQUAL
%left GREATER_THAN LESS_THAN GREATER_THAN_EQUAL LESS_THAN_EQUAL
%left PLUS MINUS
%left MULT DIV PERCENT
%left DOT
%nonassoc UMINUS NOT

%start <t list> main
%type <Block_label.t list> block_labels
%type <t list> body
%type <t> attribute
%type <t> block
%type <t> block_one_line
%type <Expr.t list> tuple
%type <(Expr.t * Expr.t) list> obj
%type <Expr.t list> fun_args
%type <Expr.t> for_tuple
%type <Expr.t> for_object
%type <string list> identifiers_rest
%type <Expr.t> expr
%type <Expr.t> expr_term
%type <Expr.t> conditional
%type <Expr.t> operation
%type <Expr.t> collection_expr
%type <string> identifier
%type <Expr.t> object_expr
%type <Expr.t> simple_expr
%type <Expr.t> tuple_expr

%%

main:
  | NEWLINE*; b = body; EOF { b }

body:
  | a = attribute; NEWLINE+; b = body { a::b }
  | bl = block; NEWLINE+; b = body { bl::b }
  | bol = block_one_line; NEWLINE+; b = body { bol::b }
  | /* */ { [] }

identifier:
  | IDENTIFIER { $1 }
  | TRUE { "true" }
  | FALSE { "false" }
  | NULL { "null" }

attribute:
  | identifier EQUAL expr { Attribute ($1, $3) }

block:
  | IDENTIFIER block_labels LBRACE NEWLINE+ body RBRACE
    { Block {type_ = $1; labels = $2; body = $5} }

block_one_line:
  | IDENTIFIER block_labels LBRACE RBRACE
    { Block {type_ = $1; labels = $2; body = []} }
  | bl_id = IDENTIFIER; labels = block_labels; LBRACE; attr = attribute RBRACE
    { Block {type_ = bl_id; labels = labels; body = [attr]} }

block_labels:
  | IDENTIFIER block_labels { (Block_label.Id $1)::$2 }
  | STRING block_labels { (Block_label.Lit $1)::$2 }
  | /* empty */ { [] }

simple_expr:
  | STRING { Expr.String $1 }
  | HEREDOC { Expr.String $1 }
  | FLOAT { Expr.Float $1 }
  | INTEGER { Expr.Int $1 }
  | TRUE { Expr.Bool true }
  | FALSE { Expr.Bool false }
  | NULL { Expr.Null }
  | IDENTIFIER { Expr.Id $1 }

collection_expr:
  | LBRACKET; NEWLINE*; tuple_expr; RBRACKET { $3 }
  | LBRACE; NEWLINE*; object_expr; RBRACE { $3 }
  | LPAREN; FOR; RPAREN { Expr.Id "for" }

expr_term:
  | simple_expr { $1 }
  | collection_expr { $1 }
  | id = IDENTIFIER; LPAREN; NEWLINE*; args = fun_args; RPAREN; { Expr.Fun_call (id, args)  }
  | LPAREN; NEWLINE*; e = expr_paren; RPAREN { e }
  | e = expr_term; LBRACKET; MULT; RBRACKET { Expr.Idx (e, Expr.Splat) }
  | e = expr_term; LBRACKET; i = expr; RBRACKET { Expr.Idx (e, i) }
  | e = expr_term; DOT; id = IDENTIFIER { Expr.Attr (e, Attr.A_string id) }
  | e = expr_term; DOT; MULT { Expr.Attr (e, Attr.A_splat) }
  | e = expr_term; DOT; i = INTEGER { Expr.Attr (e, Attr.A_int i) }

expr_term_paren:
  | e = simple_expr { e }
  | e = collection_expr { e }
  | id = IDENTIFIER; LPAREN; NEWLINE*; args = fun_args; RPAREN { Expr.Fun_call (id, args)  }
  | LPAREN; NEWLINE*; e = expr_paren; RPAREN { e }
  | e = expr_term; LBRACKET; MULT; RBRACKET { Expr.Idx (e, Expr.Splat) }
  | e = expr_term; LBRACKET; i = expr; RBRACKET { Expr.Idx (e, i) }
  | e = expr_term; DOT; id = IDENTIFIER { Expr.Attr (e, Attr.A_string id) }
  | e = expr_term; DOT; MULT { Expr.Attr (e, Attr.A_splat) }
  | e = expr_term; DOT; i = INTEGER { Expr.Attr (e, Attr.A_int i) }

operation:
 | unary_op { $1 }
 | binary_op { $1 }

operation_paren:
 | unary_op { $1 }
 | binary_op_paren { $1 }

unary_op:
  | NOT expr_term { Expr.Not $2 }
  | MINUS expr_term { Expr.Minus $2 } %prec UMINUS

binary_op:
  | expr PLUS expr { Expr.Add ($1, $3) }
  | expr MINUS expr { Expr.Subtract ($1, $3) }
  | expr MULT expr { Expr.Mult ($1, $3) }
  | expr DIV expr { Expr.Div ($1, $3) }
  | expr LESS_THAN expr { Expr.Lt ($1, $3) }
  | expr LESS_THAN_EQUAL expr { Expr.Lte ($1, $3) }
  | expr GREATER_THAN expr { Expr.Gt ($1, $3) }
  | expr GREATER_THAN_EQUAL expr { Expr.Gte ($1, $3) }
  | expr IS_EQUAL expr { Expr.Equal ($1, $3) }
  | expr NOT_EQUAL expr { Expr.Not (Expr.Equal ($1, $3)) }
  | expr LOG_AND expr { Expr.Log_and ($1, $3) }
  | expr LOG_OR expr { Expr.Log_or ($1, $3) }
  | expr PERCENT expr { Expr.Mod ($1, $3) }

binary_op_paren:
  | e1 = expr_paren; PLUS; NEWLINE*; e2 = expr_paren { Expr.Add (e1, e2) }
  | e1 = expr_paren; MINUS; NEWLINE*; e2 = expr_paren { Expr.Subtract (e1, e2) }
  | e1 = expr_paren; MULT; NEWLINE*; e2 = expr_paren { Expr.Mult (e1, e2) }
  | e1 = expr_paren; DIV; NEWLINE*; e2 = expr_paren { Expr.Div (e1, e2) }
  | e1 = expr_paren; LESS_THAN; NEWLINE*; e2 = expr_paren { Expr.Lt (e1, e2) }
  | e1 = expr_paren; LESS_THAN_EQUAL; NEWLINE*; e2 = expr_paren { Expr.Lte (e1, e2) }
  | e1 = expr_paren; GREATER_THAN; NEWLINE*; e2 = expr_paren { Expr.Gt (e1, e2) }
  | e1 = expr_paren; GREATER_THAN_EQUAL; NEWLINE*; e2 = expr_paren { Expr.Gte (e1, e2) }
  | e1 = expr_paren; IS_EQUAL; NEWLINE*; e2 = expr_paren { Expr.Equal (e1, e2) }
  | e1 = expr_paren; NOT_EQUAL; NEWLINE*; e2 = expr_paren { Expr.Not (Expr.Equal (e1, e2)) }
  | e1 = expr_paren; LOG_AND; NEWLINE*; e2 = expr_paren { Expr.Log_and (e1, e2) }
  | e1 = expr_paren; LOG_OR; NEWLINE*; e2 = expr_paren { Expr.Log_or (e1, e2) }
  | e1 = expr_paren; PERCENT; NEWLINE*; e2 = expr_paren { Expr.Mod (e1, e2) }

conditional:
  | e = expr; QUESTION_MARK; thn = expr; COLON; els = expr { Expr.Cond {if_ = e; then_ = thn; else_ = els } }

conditional_paren:
  | e = expr_paren; QUESTION_MARK; NEWLINE*; thn = expr_paren; COLON; NEWLINE*; els = expr_paren { Expr.Cond {if_ = e; then_ = thn; else_ = els } }

expr:
  | expr_term { $1 }
  | operation { $1 }
  | conditional { $1 }

expr_paren:
  | expr_term_paren; NEWLINE* { $1 }
  | operation_paren; NEWLINE* { $1 }
  | conditional_paren; NEWLINE* { $1 }

%inline tuple_expr:
  | FOR; NEWLINE*; ft = for_tuple { ft }
  | t = tuple { Expr.Tuple t }

%inline object_expr:
  | FOR; NEWLINE*; fo = for_object { fo }
  | o = obj { Expr.Object o }

tuple:
  | /* empty */ { [] }
  | e = expr; ELLIPSIS; NEWLINE* { [Expr.Ellipsis e] }
  | expr; NEWLINE* { [$1] }
  | e = expr; NEWLINE*; COMMA; NEWLINE*; t = tuple { e::t }

obj:
  | /* empty */ { [] }
  | obj_k; kv_sep; expr { [($1, $3)] }
  | e1 = obj_k; kv_sep; e2 = expr; COMMA; NEWLINE*; o = obj { (e1, e2)::o }
  | e1 = obj_k; kv_sep; e2 = expr; NEWLINE+; o = obj { (e1, e2)::o }

obj_k:
  | expr { $1 }
  | IN { Expr.Id "in" }

kv_sep:
  | EQUAL {}
  | COLON {}

fun_args:
  | /* empty */ { [] }
  | e = expr_paren; ELLIPSIS; NEWLINE* { [Expr.Ellipsis e] }
  | expr_paren; NEWLINE* { [$1] }
  | e = expr_paren; COMMA; NEWLINE*; args = fun_args { e::args }

identifiers_rest:
  | COMMA; id = IDENTIFIER; ids = identifiers_rest { id::ids }
  | /* empty */ { [] }

%inline for_tuple:
  | id = IDENTIFIER; ids = identifiers_rest; NEWLINE*; IN; NEWLINE*; in_ = expr; NEWLINE*; COLON; NEWLINE*; e = expr; NEWLINE*; if_ = collection_if?
    { Expr.For_tuple { identifiers = (id, ids); input = in_; output = e; cond = if_ } }

%inline for_object:
  | id = IDENTIFIER; ids = identifiers_rest; NEWLINE*; IN; NEWLINE*; in_ = expr; NEWLINE*; COLON; NEWLINE*; k = expr; NEWLINE*; FAT_ARROW; NEWLINE*; v =  for_obj_value; NEWLINE*; if_ = collection_if?
    { Expr.For_object { identifiers = (id, ids);
                        input = in_;
                        key_output = k;
                        value_output = v;
                        cond = if_ } }

for_obj_value:
  | expr { $1 }
  | expr; ELLIPSIS { Expr.Ellipsis $1 }

%inline collection_if:
  | IF; NEWLINE*; e = expr; NEWLINE* { e }