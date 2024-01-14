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
%type <Expr.t> ops
%type <Attr.t> attr_expr
%type <Expr.t> collection_expr
%type <Expr.t> expr
%type <string> identifier
%type <Expr.t> object_expr
%type <Expr.t> simple_expr
%type <Expr.t> tuple_expr
%type <Expr.t> idx_expr

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
  | LBRACKET NEWLINE* tuple_expr { $3 }
  | LBRACE NEWLINE* object_expr { $3 }
  | LPAREN FOR RPAREN { Expr.Id "for" }

expr:
  | simple_expr { $1 }
  | collection_expr { $1 }
  | id = IDENTIFIER; LPAREN; NEWLINE*; args = fun_args; RPAREN; { Expr.Fun_call (id, args)  }
  | LPAREN; e = expr; RPAREN { e }
  | e = expr; LBRACKET; i = idx_expr { Expr.Idx (e, i) }
  | e = expr; DOT; a = attr_expr { Expr.Attr (e, a) }
  | e = expr; QUESTION_MARK; thn = expr; COLON; els = expr { Expr.Cond {if_ = e; then_ = thn; else_ = els } }
  | ops { $1 }

tuple_expr:
  | NEWLINE*; FOR; NEWLINE*; ft = for_tuple; NEWLINE*; RBRACKET { ft }
  | NEWLINE*; t = tuple; NEWLINE*; RBRACKET { Expr.Tuple t }

object_expr:
  | NEWLINE*; FOR; NEWLINE*; fo = for_object; NEWLINE*; RBRACE { fo }
  | NEWLINE*; o = obj; NEWLINE*; RBRACE { Expr.Object o }

idx_expr:
  | MULT RBRACKET { Expr.Splat }
  | e = expr;  RBRACKET { e }

attr_expr:
  | MULT { Attr.A_splat }
  | id = IDENTIFIER { Attr.A_string id }
  | i = INTEGER { Attr.A_int i }

tuple:
  | e = expr; COMMA; NEWLINE*; t = tuple { e::t }
  | e = expr; NEWLINE+; t = tuple { e::t }
  | expr { [$1] }
  | /* empty */ { [] }

obj:
  | e1 = expr; EQUAL; e2 = expr; COMMA; NEWLINE*; o = obj { (e1, e2)::o }
  | e1 = expr; COLON; e2 = expr; COMMA; NEWLINE*; o = obj { (e1, e2)::o }
  | e1 = expr; EQUAL; e2 = expr; NEWLINE+; o = obj { (e1, e2)::o }
  | e1 = expr; COLON; e2 = expr; NEWLINE+; o = obj { (e1, e2)::o }
  | expr EQUAL expr { [($1, $3)] }
  | expr COLON expr { [($1, $3)] }
  | /* empty */ { [] }

fun_args:
  | e = expr; COMMA; NEWLINE*; args = fun_args { e::args }
  | expr { [$1] }
  | /* empty */ { [] }

identifiers_rest:
  | COMMA IDENTIFIER identifiers_rest { $2::$3 }
  | /* empty */ { [] }

for_tuple:
  | id = IDENTIFIER; ids = identifiers_rest; IN; in_ = expr; COLON; e = expr; NEWLINE*; IF; if_ =  expr
    { Expr.For_tuple { identifiers = (id, ids); input = in_; output = e; cond = Some if_ } }
  | id = IDENTIFIER; ids = identifiers_rest; IN; in_ = expr; COLON; e = expr
    { Expr.For_tuple { identifiers = (id, ids); input = in_; output = e; cond = None } }

for_object:
  | id = IDENTIFIER; ids = identifiers_rest; IN; in_ = expr; COLON; k = expr; FAT_ARROW; v =  expr; NEWLINE*; IF; if_ = expr
    { Expr.For_object { identifiers = (id, ids);
                        input = in_;
                        key_output = k;
                        value_output = v;
                        cond = Some if_ } }
  | id = IDENTIFIER; ids = identifiers_rest; IN; in_ = expr; COLON; k = expr; FAT_ARROW; v = expr
    { Expr.For_object { identifiers = (id, ids);
                        input = in_;
                        key_output = k;
                        value_output = v;
                        cond = None } }

ops:
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
  | expr LOG_OR expr {Expr.Log_or ($1, $3) }
  | expr PERCENT expr { Expr.Mod ($1, $3) }
  | NOT expr { Expr.Not $2 }
  | MINUS expr { Expr.Minus $2 } %prec UMINUS
