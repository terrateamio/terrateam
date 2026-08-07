%{
  open Hcl_parser_value

  let expr_to_fun_call e args =
    let id =
      (function
        | Expr.Id id -> id
        | Expr.Bool true -> "true"
        | Expr.Bool false -> "false"
        | Expr.Null -> "null"
        | _ -> failwith "Function call requires identifier") e
    in
    Expr.Fun_call (id, args)

  (* HCL forbids setting the same argument more than once per body scope. Run
     this single-pass O(n) validation once per completed body (top-level and
     block body) rather than per-item during construction, which would make the
     whole parse O(n²) in the number of body items. *)
  let check_no_duplicate_attributes body =
    let seen = Hashtbl.create (List.length body) in
    List.iter
      (function
        | Attribute (name, _) ->
            if Hashtbl.mem seen name then
              failwith
                (Printf.sprintf
                   "Attribute %S redefined: each argument may be set only once"
                   name)
            else Hashtbl.add seen name ()
        | _ -> ())
      body;
    body

  (* Decide whether a numeric literal's raw source represents an exact
     integer (value = mantissa × 10^exponent, with no fractional part)
     and, if so, whether it fits OCaml's native int. Operates on the raw
     lexeme rather than the already-rounded [float64] the lexer computes,
     so we don't conflate "source was a float" with "float64 rounded to
     an integer". Mirrors the shim's [cty.Number] encoding (big.Float
     with exact tracking, Int64 if [IsInt() && acc == Exact]).

     Example cases that diverged when routed through float64:
     - [123456789012345678.0]: fits int64 exactly, but [float_of_string]
       rounds to [123456789012345680].
     - [9999999999999999.0]: float rounds UP to [10000000000000000].
     - [1e-400]: underflows to 0.0, which [Float.is_integer] says is
       integer — but the source value is not actually 0. *)
  let parse_number_literal_to_expr s =
    let slen = String.length s in
    let exp_pos =
      let rec find i =
        if i >= slen then None
        else
          let c = s.[i] in
          if c = 'e' || c = 'E' then Some i else find (i + 1)
      in
      find 0
    in
    let mantissa, exp =
      match exp_pos with
      | Some i ->
          let m = String.sub s 0 i in
          let e_str = String.sub s (i + 1) (slen - i - 1) in
          (m, int_of_string e_str)
      | None -> (s, 0)
    in
    let int_part, frac_part =
      match String.index_opt mantissa '.' with
      | Some i ->
          ( String.sub mantissa 0 i,
            String.sub mantissa (i + 1) (String.length mantissa - i - 1) )
      | None -> (mantissa, "")
    in
    let digits = int_part ^ frac_part in
    let dlen = String.length digits in
    let effective_exp = exp - String.length frac_part in
    let all_zeros s =
      let n = String.length s in
      let rec loop i = i >= n || (s.[i] = '0' && loop (i + 1)) in
      loop 0
    in
    let is_exact_int, int_str =
      if effective_exp >= 0 then (true, digits ^ String.make effective_exp '0')
      else
        let abs_exp = -effective_exp in
        if abs_exp >= dlen then
          (* Pure fractional: integer part is 0; the value is exactly 0
             iff every source digit is 0. *)
          (all_zeros digits, "0")
        else
          let trailing_frac = String.sub digits (dlen - abs_exp) abs_exp in
          (all_zeros trailing_frac, String.sub digits 0 (dlen - abs_exp))
    in
    if is_exact_int then (
      try Expr.Int (int_of_string int_str)
      with Failure _ ->
        (* The integer doesn't fit OCaml's 63-bit native int. Fall back
           to [Float] so we don't reject the file — matches the existing
           lexer-level overflow behavior for raw [Plus digit] integers. *)
        Expr.Float (float_of_string s))
    else Expr.Float (float_of_string s)
%}

%token <string> IDENTIFIER
(* [foo::bar::baz], any identifier containing [::]. hclsyntax treats
   [::] as a function-selector: a namespaced identifier must be
   immediately followed by [(] (a function call). Separating the token
   from [IDENTIFIER] lets the grammar restrict it to that position, so
   bareword [foo::bar] and traversal base [foo::bar.x] both reject
   instead of producing a spurious [Id "foo::bar"] node. *)
%token <string> NAMESPACED_IDENTIFIER
%token <string> STRING
(* INTEGER / FLOAT carry both the raw source lexeme and the parsed value.
   Most grammar positions use the parsed value (e.g. [Expr.Int]), but
   object keys use the raw lexeme so unquoted numeric keys round-trip as
   they appeared in source: [{ 007 = ... }] → [Id "007"], [{ 1e3 = ... }] →
   [Id "1e3"]. This matches hclsyntax, whose [ObjectConsKeyExpr] encoder
   reads source bytes. *)
%token <string * int> INTEGER
%token <string * float> FLOAT
%token <bool * string * string> HEREDOC
%token TRUE FALSE NULL
%token LPAREN RPAREN
%token LBRACKET RBRACKET
%token LBRACE RBRACE
%token FOR IN IF
%token FAT_ARROW
%token EQUAL COMMA DOT COLON DOUBLE_COLON ELLIPSIS QUESTION_MARK PERCENT
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

%start <t list> main
%start <Expr.t> expr_only
%start <Expr.t> expr_paren_only
%type <Block_label.t list> block_labels
%type <t list> body
%type <t> attribute
%type <t> block
%type <t> block_one_line
%type <Expr.t list> tuple
%type <(Obj_key.t * Expr.t) list> obj
%type <(Obj_key.t * Expr.t) list> obj_rest
%type <Obj_key.t> obj_k_first
%type <Obj_key.t> obj_k
%type <Expr.t list> fun_args
%type <Expr.t> for_tuple
%type <Expr.t> for_object
%type <Expr.t> expr
%type <Expr.t> expr_term
%type <Expr.t> conditional
%type <Expr.t> operation
%type <Expr.t> collection_expr
%type <string> identifier
%type <Expr.t> object_expr
%type <Expr.t> simple_expr
%type <Expr.t> tuple_expr
%type <Expr.t> expr_paren_for_access
%type <Expr.t> expr_term_paren_access

%%

main:
  | NEWLINE*; b = body; EOF { check_no_duplicate_attributes b }

expr_only:
  | NEWLINE*; e = expr; NEWLINE*; EOF { e }

(* Expression entry point for template-interpolation content (inside [${...}]
   and [%{if ...}] / [%{for ...}] directives). Uses [expr_paren] so NEWLINEs
   are non-significant — the shim treats interpolations as newline-insensitive
   contexts, whereas [expr] is the top-level, newline-significant grammar. *)
expr_paren_only:
  | NEWLINE*; e = expr_paren; NEWLINE*; EOF { e }

body:
  | a = attribute; NEWLINE+; b = body { a :: b }
  | bl = block; NEWLINE+; b = body { bl :: b }
  | bol = block_one_line; NEWLINE+; b = body { bol :: b }
  | /* */ { [] }

identifier:
  | IDENTIFIER { $1 }
  | TRUE { "true" }
  | FALSE { "false" }
  | NULL { "null" }

(* After a dot, all keywords are valid attribute names. *)
attr_identifier:
  | identifier { $1 }
  | FOR { "for" }
  | IN { "in" }
  | IF { "if" }

attribute:
  | attr_identifier EQUAL expr { Attribute ($1, $3) }

(* Block type: [IDENTIFIER] or a keyword token. hclsyntax tokenizes
   [true], [false], [null] contextually, so [true { x = 1 }] is a valid
   block with type [true]. [FOR] / [IN] / [IF] are intentionally excluded:
   they'd shadow the attribute-with-keyword-name form ([for = 1] is a
   legitimate attribute via [attr_identifier]) and would be ambiguous at
   the start of the body. *)
block_type:
  | IDENTIFIER { $1 }
  | TRUE { "true" }
  | FALSE { "false" }
  | NULL { "null" }

block:
  | block_type block_labels LBRACE NEWLINE+ body RBRACE
    { Block {type_ = $1; labels = $2; body = check_no_duplicate_attributes $5} }

block_one_line:
  | block_type block_labels LBRACE RBRACE
    { Block {type_ = $1; labels = $2; body = []} }
  | bl_id = block_type; labels = block_labels; LBRACE; attr = attribute RBRACE
    { Block {type_ = bl_id; labels = labels; body = [attr]} }

block_labels:
  | IDENTIFIER block_labels { (Block_label.Id $1)::$2 }
  | STRING block_labels { (Block_label.Lit $1)::$2 }
  (* Keyword tokens as block labels: [resource true name {}],
     [resource null name {}]. hclsyntax tokenizes these as [TokenIdent]
     contextually, so any keyword is valid in a label position. *)
  | TRUE block_labels { (Block_label.Id "true")::$2 }
  | FALSE block_labels { (Block_label.Id "false")::$2 }
  | NULL block_labels { (Block_label.Id "null")::$2 }
  | FOR block_labels { (Block_label.Id "for")::$2 }
  | IN block_labels { (Block_label.Id "in")::$2 }
  | IF block_labels { (Block_label.Id "if")::$2 }
  | /* empty */ { [] }

simple_expr:
  | STRING { Expr.String $1 }
  | HEREDOC { let (strip, marker, body) = $1 in if strip then Expr.Heredoc' (marker, body) else Expr.Heredoc (marker, body) }
  | FLOAT { parse_number_literal_to_expr (fst $1) }
  | INTEGER { Expr.Int (snd $1) }
  | TRUE { Expr.Bool true }
  | FALSE { Expr.Bool false }
  | NULL { Expr.Null }
  | IDENTIFIER { Expr.Id $1 }
  (* hclsyntax accepts [for], [in], [if] as bare identifier references in
     expression positions ([x = for], [y = if], [x = for + 1]). The
     keyword tokens are mode-switching only in specific positions:
     [FOR] opens a for-comprehension at the start of [[..]] / [{..}],
     [IF] introduces the [collection_if], and [IN] separates the loop
     variable from its input — all covered by more-specific rules that
     match longer prefixes. *)
  | FOR { Expr.Id "for" }
  | IN { Expr.Id "in" }
  | IF { Expr.Id "if" }

collection_expr:
  | LBRACKET; NEWLINE*; tuple_expr; RBRACKET { $3 }
  | LBRACE; NEWLINE*; object_expr; RBRACE { $3 }
  | LPAREN; FOR; RPAREN { Expr.Id "for" }

(* Top-level expression terms — NEWLINE is significant *)
expr_term:
  | simple_expr { $1 }
  | collection_expr { $1 }
  | id = IDENTIFIER; LPAREN; NEWLINE*; args = fun_args; RPAREN; { Expr.Fun_call (id, args)  }
  (* Function calls named after a keyword token: [for(1)], [true(1)],
     [null()], etc. hclsyntax doesn't reserve any of these as identifier
     tokens, so any [KEYWORD LPAREN ...] reads as a regular function
     call. The specific-token [simple_expr -> TRUE / FALSE / NULL / FOR /
     IN / IF] reductions still fire when [LPAREN] is NOT the lookahead,
     so [x = true] stays a [Bool], [x = for] stays a plain [Id "for"],
     etc. *)
  | FOR;   LPAREN; NEWLINE*; args = fun_args; RPAREN { Expr.Fun_call ("for",   args) }
  | IN;    LPAREN; NEWLINE*; args = fun_args; RPAREN { Expr.Fun_call ("in",    args) }
  | IF;    LPAREN; NEWLINE*; args = fun_args; RPAREN { Expr.Fun_call ("if",    args) }
  | TRUE;  LPAREN; NEWLINE*; args = fun_args; RPAREN { Expr.Fun_call ("true",  args) }
  | FALSE; LPAREN; NEWLINE*; args = fun_args; RPAREN { Expr.Fun_call ("false", args) }
  | NULL;  LPAREN; NEWLINE*; args = fun_args; RPAREN { Expr.Fun_call ("null",  args) }
  (* Namespaced function call: [core::max(...)], [foo::bar::baz(...)].
     Only valid immediately before [(]; bareword [foo::bar] or traversal
     [foo::bar.x] have no rule and reject, matching hclsyntax's
     "Missing open parenthesis; Function selector must be followed by an
     open parenthesis to begin the function call." *)
  | id = NAMESPACED_IDENTIFIER; LPAREN; NEWLINE*; args = fun_args; RPAREN
    { Expr.Fun_call (id, args) }
  (* Whitespaced variant: [foo :: bar(...)], [core :: max(1, 2)]. hclsyntax
     tokenizes [::] as its own token regardless of surrounding whitespace;
     the Menhir lexer only produces [NAMESPACED_IDENTIFIER] when [::] is
     directly adjacent to identifier chars, so with spaces we fall back to
     [IDENTIFIER (DOUBLE_COLON IDENTIFIER)+ LPAREN ...]. *)
  | head = namespaced_name_with_space; LPAREN; NEWLINE*; args = fun_args; RPAREN
    { Expr.Fun_call (head, args) }
  | LPAREN; NEWLINE*; e = expr_paren; RPAREN { e }
  | e = expr_term; LBRACKET; MULT; RBRACKET { Expr.Idx (e, Expr.Splat) }
  | e = expr_term; LBRACKET; NEWLINE*; i = expr_paren; NEWLINE*; RBRACKET { Expr.Idx (e, i) }
  (* No [NEWLINE*] between DOT and the accessor token *)
  | e = expr_term; DOT; id = attr_identifier { Expr.Attr (e, Attr.A_string id) }
  | e = expr_term; DOT; i = INTEGER { Expr.Attr (e, Attr.A_int (snd i)) }

(* A space-separated namespaced name ([foo :: bar], [core :: max :: v]),
   built left-associatively. Only usable immediately before [(]; standalone
   or traversal uses reject because [expr_term] lists no other position
   for it. *)
namespaced_name_with_space:
  | a = IDENTIFIER; DOUBLE_COLON; b = IDENTIFIER { a ^ "::" ^ b }
  | head = namespaced_name_with_space; DOUBLE_COLON; tail = IDENTIFIER
    { head ^ "::" ^ tail }

(* Attr-only splat as a distinct non-terminal so the chain after [.*] cannot
   re-enter another [.*]: hclsyntax rejects [foo.*.*] and [foo.*.x.*.y] with
   "Nested splat expression not allowed; A splat expression (*) cannot be
   used inside another attribute-only splat expression." Index-splats ([*])
   chain freely in both directions ([foo[*][*]], [foo.*[*]], [foo[*].*]), so
   they stay in [expr_term] and [attr_splat] allows them as tail accessors. *)
attr_splat:
  | e = expr_term; DOT; MULT { Expr.Attr (e, Attr.A_splat) }
  | e = attr_splat; DOT; id = attr_identifier { Expr.Attr (e, Attr.A_string id) }
  | e = attr_splat; DOT; i = INTEGER { Expr.Attr (e, Attr.A_int (snd i)) }
  | e = attr_splat; LBRACKET; MULT; RBRACKET { Expr.Idx (e, Expr.Splat) }
  | e = attr_splat; LBRACKET; NEWLINE*; i = expr_paren; NEWLINE*; RBRACKET { Expr.Idx (e, i) }

(* Parenthesized expression terms — NEWLINE is non-significant.
   Base cases only; chained access (DOT, LBRACKET, function calls) is handled by
   expr_term_paren_access via expr_paren_for_access, which absorbs trailing NEWLINEs
   before the accessor token. *)
expr_term_paren:
  | e = simple_expr { e }
  | e = collection_expr { e }
  (* Namespaced function call: [core::max(...)], [provider::terraform::decode_tfvars(...)].
     Mirrors the [expr_term] rule so namespaced calls are accepted inside parens
     (function arguments, interpolation bodies, etc.) — without this rule, nesting
     a namespaced call as a [fun_args] argument or interpolation expression rejects
     with FUNC_ARG_EXPECTED, even though the same call is valid at top level. *)
  | id = NAMESPACED_IDENTIFIER; LPAREN; NEWLINE*; args = fun_args; RPAREN
    { Expr.Fun_call (id, args) }
  | head = namespaced_name_with_space; LPAREN; NEWLINE*; args = fun_args; RPAREN
    { Expr.Fun_call (head, args) }
  | LPAREN; NEWLINE*; e = expr_paren; RPAREN { e }
  | e = expr_term_paren_access { e }

(* Absorbs trailing NEWLINEs after an expression term, for use before an accessor token
   (DOT, LBRACKET, LPAREN). The LR(1) lookahead disambiguates: DOT/LBRACKET/LPAREN reduce
   here; all other tokens reduce to expr_paren instead, since those tokens are not in
   FOLLOW(expr_paren_for_access). *)
expr_paren_for_access:
  | e = expr_term_paren; NEWLINE* { e }

expr_term_paren_access:
  | e = expr_paren_for_access; DOT; NEWLINE*; id = attr_identifier
      { Expr.Attr (e, Attr.A_string id) }
  | e = expr_paren_for_access; DOT; NEWLINE*; MULT
      { Expr.Attr (e, Attr.A_splat) }
  | e = expr_paren_for_access; DOT; NEWLINE*; i = INTEGER
      { Expr.Attr (e, Attr.A_int (snd i)) }
  | e = expr_paren_for_access; LBRACKET; MULT; RBRACKET
      { Expr.Idx (e, Expr.Splat) }
  | e = expr_paren_for_access; LBRACKET; NEWLINE*; i = expr_paren; RBRACKET
      { Expr.Idx (e, i) }
  | e = expr_paren_for_access; LPAREN; NEWLINE*; args = fun_args; RPAREN
      { expr_to_fun_call e args }

operation:
 | unary_op { $1 }
 | binary_op { $1 }

operation_paren:
 | unary_op { $1 }
 | binary_op_paren { $1 }

unary_op:
  | NOT expr_term { Expr.Not $2 }
  | NOT unary_op { Expr.Not $2 }
  | MINUS expr_term { Expr.Minus $2 }
  | MINUS unary_op { Expr.Minus $2 }

(* [binop] and [cond] are parameterized over the expression-level rule [E] (top-level [expr]
   vs. parenthesized [expr_paren]) and the optional-separator [NL] that appears between
   operator tokens and the right-hand operand. In top-level contexts NEWLINE is significant
   so [NL] is empty ([no_nl]); inside parentheses it is [NEWLINE*]. Sharing the arms this way
   keeps [binary_op] vs [binary_op_paren] (and [conditional] vs [conditional_paren]) from
   drifting out of sync when operators are added or changed. *)

%inline no_nl: /* empty */ { () }

%inline binop(E, NL):
  | e1 = E; PLUS;               NL; e2 = E { Expr.Add (e1, e2) }
  | e1 = E; MINUS;              NL; e2 = E { Expr.Subtract (e1, e2) }
  | e1 = E; MULT;               NL; e2 = E { Expr.Mult (e1, e2) }
  | e1 = E; DIV;                NL; e2 = E { Expr.Div (e1, e2) }
  | e1 = E; LESS_THAN;          NL; e2 = E { Expr.Lt (e1, e2) }
  | e1 = E; LESS_THAN_EQUAL;    NL; e2 = E { Expr.Lte (e1, e2) }
  | e1 = E; GREATER_THAN;       NL; e2 = E { Expr.Gt (e1, e2) }
  | e1 = E; GREATER_THAN_EQUAL; NL; e2 = E { Expr.Gte (e1, e2) }
  | e1 = E; IS_EQUAL;           NL; e2 = E { Expr.Equal (e1, e2) }
  | e1 = E; NOT_EQUAL;          NL; e2 = E { Expr.Not_equal (e1, e2) }
  | e1 = E; LOG_AND;            NL; e2 = E { Expr.Log_and (e1, e2) }
  | e1 = E; LOG_OR;             NL; e2 = E { Expr.Log_or (e1, e2) }
  | e1 = E; PERCENT;            NL; e2 = E { Expr.Mod (e1, e2) }

binary_op:
  | bop = binop(expr, no_nl) { bop }

binary_op_paren:
  | bop = binop(expr_paren, list(NEWLINE)) { bop }

%inline cond(E, NL):
  | e = E; QUESTION_MARK; NL; thn = E; COLON; NL; els = E
    { Expr.Cond {if_ = e; then_ = thn; else_ = els } }

conditional:
  | c = cond(expr, no_nl) { c }

conditional_paren:
  | c = cond(expr_paren, list(NEWLINE)) { c }

expr:
  | expr_term { $1 }
  | attr_splat { $1 }
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

(* No `expr_paren ELLIPSIS` here: hclsyntax's parseTupleCons only
   accepts `,` or `]` between elements and rejects `...` entirely. The
   grouping ellipsis is legal only as the output of a for-object
   expression and as the trailing argument of a function call; see
   [for_obj_value] and [fun_args]. *)
tuple:
  | /* empty */ { [] }
  | expr_paren { [$1] }
  | e = expr_paren; COMMA; NEWLINE*; t = tuple { e::t }

(* Two obj rules to encode hclsyntax's position-sensitive [for]:
   [parseObjectCons] peeks [for] *only at the first key position* to switch
   into for-expression mode. At later positions [for] is an ordinary object
   key. So [{for = 1}] is rejected but [{k = 0, for = 1}] is accepted. We
   mirror that by using [obj_k_first] (no [FOR]) for the opening key and
   [obj_k] (allows [FOR]) for all subsequent keys. *)
obj:
  | /* empty */ { [] }
  | obj_k_first; kv_sep; expr { [($1, $3)] }
  | e1 = obj_k_first; kv_sep; e2 = expr; COMMA; NEWLINE*; o = obj_rest { (e1, e2)::o }
  | e1 = obj_k_first; kv_sep; e2 = expr; NEWLINE+; o = obj_rest { (e1, e2)::o }

obj_rest:
  | /* empty */ { [] }
  | obj_k; kv_sep; expr { [($1, $3)] }
  | e1 = obj_k; kv_sep; e2 = expr; COMMA; NEWLINE*; o = obj_rest { (e1, e2)::o }
  | e1 = obj_k; kv_sep; e2 = expr; NEWLINE+; o = obj_rest { (e1, e2)::o }

obj_k_expr:
  /* relevant part of expr_term (see 'expr'): everything except simple_expr, collection_expr, and splat */
  | id = IDENTIFIER; LPAREN; NEWLINE*; args = fun_args; RPAREN; { Expr.Fun_call (id, args)  }
  | e = expr_term; LBRACKET; NEWLINE*; i = expr_paren; NEWLINE*; RBRACKET { Expr.Idx (e, i) }
  | e = expr_term; DOT; id = IDENTIFIER { Expr.Attr (e, Attr.A_string id) }
  | e = expr_term; DOT; i = INTEGER { Expr.Attr (e, Attr.A_int (snd i)) }
  /* non expr_term parts of 'expr' */
  | operation { $1 }
  | conditional { $1 }

obj_k_first:
  | STRING { Obj_key.Quoted $1 }
  | IDENTIFIER { Obj_key.Bare $1 }
  | INTEGER { Obj_key.Bare (fst $1) }
  | FLOAT { Obj_key.Bare (fst $1) }
  | LPAREN; NEWLINE*; e = expr_paren; RPAREN { Obj_key.Computed e }
  | obj_k_expr { Obj_key.Expr $1 }
  | IN { Obj_key.Bare "in" }
  | IF { Obj_key.Bare "if" }
  | TRUE { Obj_key.Bare "true" }
  | FALSE { Obj_key.Bare "false" }
  | NULL { Obj_key.Bare "null" }

obj_k:
  | obj_k_first { $1 }
  | FOR { Obj_key.Bare "for" }

kv_sep:
  | EQUAL {}
  | COLON {}

fun_args:
  | /* empty */ { [] }
  | e = expr_paren; ELLIPSIS; NEWLINE* { [Expr.Ellipsis e] }
  | expr_paren { [$1] }
  | e = expr_paren; COMMA; NEWLINE*; args = fun_args { e::args }

/* Note: OpenTofu accepts parenthesized loop variables, e.g. [for (x) in ...], but we
   intentionally do not support this. It is an extremely obscure syntax with no practical use.

   Note: The 'in' expression uses 'expr_paren' with the COLON/QUESTION_MARK precedence declarations
   resolving the ambiguity between the ternary else ':' and the for-separator ':'. */
(* A for-loop variable name. hclsyntax reads the loop-variable position as a plain
   identifier token, so keyword-spelled names are accepted here as contextual
   identifiers, matching [tofu validate]. The value keywords [true]/[false]/[null]
   reuse the [identifier] rule; the structural tokens [for]/[in]/[if] are excluded
   because they are ambiguous in this position (they open / separate / guard the
   comprehension itself). *)
for_ident:
  | id = identifier { id }

%inline for_tuple:
  | id = for_ident; NEWLINE*; COMMA; NEWLINE*; id2 = for_ident; NEWLINE*; IN; NEWLINE*; in_ = expr_paren; COLON; NEWLINE*; e = for_tuple_value; if_ = collection_if?
    { Expr.For_tuple { identifiers = (id, [id2]); input = in_; output = e; cond = if_ } }
  | id = for_ident; NEWLINE*; IN; NEWLINE*; in_ = expr_paren; COLON; NEWLINE*; e = for_tuple_value; if_ = collection_if?
    { Expr.For_tuple { identifiers = (id, []); input = in_; output = e; cond = if_ } }

%inline for_object:
  | id = for_ident; NEWLINE*; COMMA; NEWLINE*; id2 = for_ident; NEWLINE*; IN; NEWLINE*; in_ = expr_paren; COLON; NEWLINE*; k = expr_paren; FAT_ARROW; NEWLINE*; v = for_obj_value; if_ = collection_if?
    { Expr.For_object { identifiers = (id, [id2]);
                        input = in_;
                        key_output = k;
                        value_output = v;
                        cond = if_ } }
  | id = for_ident; NEWLINE*; IN; NEWLINE*; in_ = expr_paren; COLON; NEWLINE*; k = expr_paren; FAT_ARROW; NEWLINE*; v = for_obj_value; if_ = collection_if?
    { Expr.For_object { identifiers = (id, []);
                        input = in_;
                        key_output = k;
                        value_output = v;
                        cond = if_ } }

(* HCL grammar forbids the grouping ellipsis (...) in the output of a
   for-tuple expression; it is only valid in for-object expressions and in
   function-argument expansion. See [for_obj_value] and [fun_args]. *)
for_tuple_value:
  | expr_paren { $1 }

for_obj_value:
  | expr_paren { $1 }
  | expr_paren; ELLIPSIS; NEWLINE* { Expr.Ellipsis $1 }

%inline collection_if:
  | IF; NEWLINE*; e = expr_paren { e }
