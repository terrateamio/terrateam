%{
  open struct module M = Mql_ast end
%}

%token <string> IDENTIFIER
%token <string> STRING
%token <int> INTEGER
%token <float> FLOAT

%token LPAREN RPAREN LBRACKET RBRACKET
%token NOT IS IS_NOT IS_DISTINCT_FROM IS_NOT_DISTINCT_FROM
%token SELECT FROM WHERE GROUP HAVING ORDER  LIMIT
%token COUNT
%token WITH MATERIALIZED AS BY ON
%token INNER LEFT RIGHT JOIN
%token DOT COMMA DOUBLE_COLON
%token PLUS MINUS STAR DIV DOUBLE_PIPE
%token ASC DESC
%token JSON_VAL JSON_TEXT JSON_OBJ_QUERY JSON_SUBSET
%token EQUAL NOT_EQUAL LT LTE GT GTE IN LIKE ILIKE
%token AND OR
%token NULL TRUE FALSE
%token UNNEST EXISTS UNION ALL

%token EOF

%left OR
%left AND
%left EQUAL NOT_EQUAL LT LTE GT GTE JSON_SUBSET IS IS_NOT IN IS_DISTINCT_FROM IS_NOT_DISTINCT_FROM LIKE ILIKE NOT
%left PLUS MINUS
%left STAR DIV
%left DOUBLE_PIPE
%left JSON_VAL JSON_TEXT JSON_OBJ_QUERY
%right UMINUS
%right DOUBLE_COLON
%left DOT
%left LBRACKET

%start <Mql_ast.t> start
%start <Mql_ast.expr> standalone_expr

%%

start:
  | q = query EOF
    { q }
    [@name start]

standalone_expr:
  | e = expr EOF
    { e }
    [@name standalone_expr]

cte:
  | tbl = IDENTIFIER AS LPAREN q = query RPAREN
    { (false, tbl, q) }
    [@name cte_definition]
  | tbl = IDENTIFIER AS MATERIALIZED LPAREN q = query RPAREN
    { (true, tbl, q) }
    [@name cte_definition_materialized]

ctes:
  | c = cte
    { [ c ] }
    [@name cte]
  | cs = ctes COMMA c = cte
    { cs @ [ c ] }
    [@name ctes]

query:
  | b = query_body ol = order_by_opt
    { let (order_by, limit) = ol in
      M.Query { body = b; order_by; limit } }
    [@name query]
  | WITH cs = ctes q = query
    { List.fold_right
        (fun (materialized, name, query) body -> M.With { materialized; name; query; body })
        cs
        q }
    [@name with_query]

query_body:
  | t = union_term
    { t }
    [@name qb_term]
  | l = query_body UNION r = union_term
    { M.Union { all = false; left = l; right = r } }
    [@name qb_union]
  | l = query_body UNION ALL r = union_term
    { M.Union { all = true; left = l; right = r } }
    [@name qb_union_all]

union_term:
  | s = select_core
    { M.Select s }
    [@name ut_select]
  | LPAREN q = query RPAREN
    { M.Paren q }
    [@name ut_paren]

select_core:
  | SELECT sl = select_list FROM ts = tables rest = select_opt
    { let (joins, where, group_by, having) = rest in
      M.{
          select_list = sl;
          from = ts;
          joins;
          where;
          group_by;
          having
        } }
    [@name select_core]

select_opt:
  | js = joins rest = where_opt
    { let (where, group_by, having) = rest in
      (js, where, group_by, having) }
    [@name with_joins]
  | rest = where_opt
    { let (where, group_by, having) = rest in
      ([ ], where, group_by, having) }
    [@name no_joins]

join:
  | INNER JOIN t = table ON e = expr
    { { M.join_type = M.Inner; table = t; on_ = e } }
    [@name inner_join]
  | LEFT JOIN t = table ON e = expr
    { { M.join_type = M.Left; table = t; on_ = e } }
    [@name left_join]
  | RIGHT JOIN t = table ON e = expr
    { { M.join_type = M.Right; table = t; on_ = e } }
    [@name right_join]

joins:
  | j = join
    { [ j ] }
    [@name join]
  | js = joins j = join
    { js @ [ j ] }
    [@name joins]

where_opt:
  | WHERE e = expr rest = group_by_opt
    { let (group_by, having) = rest in
      (Some e, group_by, having) }
    [@name where]
  | rest = group_by_opt
    { let (group_by, having) = rest in
      (None, group_by, having) }
    [@name no_where]

group_by_exprs:
  | e = expr
    { [ e ] }
    [@name group_by_expr]
  | es = group_by_exprs COMMA e = expr
    { es @ [ e ] }
    [@name group_by_exprs]

group_by_opt:
  | GROUP BY es = group_by_exprs HAVING having = expr
    { (Some es, Some having) }
    [@name group_by_having]
  | GROUP BY es = group_by_exprs
    { (Some es, None) }
    [@name group_by_no_having]
  | /* empty */
    { (None, None) }
    [@name no_group_by]

order_by_expr:
  | e = expr DESC
    { (e, Some M.Desc) }
    [@name order_by_desc]
  | e = expr ASC
    { (e, Some M.Asc) }
    [@name order_by_asc]
  | e = expr
    { (e, None) }
    [@name order_by_bare]

order_by_exprs:
  | e = order_by_expr
    { [ e ] }
    [@name order_by_expr]
  | es = order_by_exprs COMMA e = order_by_expr
    { es @ [ e ] }
    [@name order_by_exprs]

order_by_opt:
  | ORDER BY t = order_by_exprs rest = limit_opt
    { let limit = rest in
      (Some t, limit) }
    [@name order_by]
  | rest = limit_opt
    { let limit = rest in
      (None, limit) }
    [@name no_order_by]

limit_opt:
  | /* empty */ 
    { None }
    [@name eof]
  | LIMIT i = INTEGER
    { Some i }
    [@name limit]

select_list:
  | STAR
    { M.Star }
    [@name select_list_star]
  | slc = select_list_columns
    { M.Columns slc }
    [@name select_list]

column:
  | e = expr AS alias = IDENTIFIER
    { { M.expr = e; alias = Some alias } }
    [@name column_with_alias]
  | e = expr
    { { M.expr = e; alias = None } }
    [@name column_no_alias]

select_list_columns:
  | c = column
    { [ c ] }
    [@name select_list_column]
  | slc = select_list_columns COMMA c = column
    { slc @ [ c ] }
    [@name select_list_columns]

table:
  | name = IDENTIFIER AS alias = IDENTIFIER
    { { M.name; alias = Some alias } }
    [@name table_with_alias]
  | name = IDENTIFIER
    { { M.name; alias = None } }
    [@name table_no_alias]

from_item:
  | t = table
    { M.Table_ref t }
    [@name from_table]
  | UNNEST LPAREN e = expr RPAREN AS alias = IDENTIFIER
    { M.Unnest { expr = e; alias } }
    [@name from_unnest]

tables:
  | t = from_item
    { [ t ] }
    [@name table]
  | ts = tables COMMA t = from_item
    { ts @ [ t ] }
    [@name tables]

expr:
  | LPAREN t = tuple RPAREN
    { M.Tuple t }
    [@name tuple]
  | LPAREN e = expr RPAREN
    { e }
    [@name paren]
  | e1 = expr PLUS e2 = expr
    { M.Add (e1, e2) }
    [@name add]
  | e1 = expr MINUS e2 = expr
    { M.Sub (e1, e2) }
    [@name sub]
  | e1 = expr STAR e2 = expr
    { M.Mult (e1, e2) }
    [@name mult]
  | e1 = expr DIV e2 = expr
    { M.Div (e1, e2) }
    [@name div]
  | e1 = expr AND e2 = expr
    { M.And (e1, e2) }
    [@name and_]
  | e1 = expr OR e2 = expr
    { M.Or (e1, e2) }
    [@name or_]
  | e1 = expr EQUAL e2 = expr
    { M.Eq (e1, e2) }
    [@name equal]
  | e1 = expr NOT_EQUAL e2 = expr
    { M.Not_eq (e1, e2) }
    [@name not_equal]
  | e1 = expr IS e2 = expr
    { M.Is (e1, e2) }
    [@name is_]
  | e1 = expr IS_NOT e2 = expr
    { M.Is_not (e1, e2) }
    [@name is_not]
  | e1 = expr LIKE e2 = expr
    { M.Like (e1, e2) }
    [@name like]
  | e1 = expr NOT LIKE e2 = expr
    { M.Not_like (e1, e2) }
    [@name not_like]
  | e1 = expr ILIKE e2 = expr
    { M.Ilike (e1, e2) }
    [@name ilike]
  | e1 = expr NOT ILIKE e2 = expr
    { M.Not_ilike (e1, e2) }
    [@name not_ilike]
  | e1 = expr LT e2 = expr
    { M.Lt (e1, e2) }
    [@name lt]
  | e1 = expr LTE e2 = expr
    { M.Lte (e1, e2) }
    [@name lte]
  | e1 = expr GT e2 = expr
    { M.Gt (e1, e2) }
    [@name gt]
  | e1 = expr GTE e2 = expr
    { M.Gte (e1, e2) }
    [@name gte]
  | e1 = expr IS_DISTINCT_FROM e2 = expr
    { M.Is_distinct_from (e1, e2) }
    [@name is_distinct_from]
  | e1 = expr IS_NOT_DISTINCT_FROM e2 = expr
    { M.Is_not_distinct_from (e1, e2) }
    [@name is_not_distinct_from]
  | e1 = expr IN LPAREN t = in_list RPAREN
    { M.In (e1, t) }
    [@name in_]
  | e1 = expr IN LPAREN q = query RPAREN
    { M.In_query (e1, q) }
    [@name in_query]
  | EXISTS LPAREN q = query RPAREN
    { M.Exists q }
    [@name exists]
  | e1 = expr LBRACKET e2 = expr RBRACKET
    { M.Index (e1, e2) }
    [@name index]
  | e1 = expr DOUBLE_COLON s = IDENTIFIER
    { M.Cast (e1, s) }
    [@name cast]
  | e1 = expr DOUBLE_PIPE e2 = expr
    { M.Concat (e1, e2) }
    [@name concat]
  | e1 = expr DOT s = IDENTIFIER
    { M.Field_select (e1, s) }
    [@name field_select]
  | e1 = expr JSON_VAL e2 = expr
    { M.Json_val (e1, e2) }
    [@name json_val]
  | e1 = expr JSON_TEXT e2 = expr
    { M.Json_text (e1, e2) }
    [@name json_text]
  | e1 = expr JSON_OBJ_QUERY q = STRING
    { M.Json_obj_query (e1, q) }
    [@name json_obj_query]
  | e1 = expr JSON_SUBSET e2 = expr
    { M.Json_subset (e1, e2) }
    [@name json_subset]
  | MINUS e = expr %prec UMINUS
    { M.Negate e }
    [@name negate]
  | NOT e = expr %prec UMINUS
    { M.Not e }
    [@name not_]
  | COUNT LPAREN STAR RPAREN
    { M.Count M.Star }
    [@name count_star]
  | name = IDENTIFIER LPAREN RPAREN
    { M.Func {M.name; args = [] } }
    [@name fun_no_args]
  | name = IDENTIFIER LPAREN args = fun_args RPAREN
    { M.Func {M.name; args} }
    [@name fun_call]
  | id = IDENTIFIER
    { M.Identifier id }
    [@name identifier]
  | s = STRING
    { M.String s }
    [@name string]
  | i = INTEGER
    { M.Int i }
    [@name integer]
  | fl = FLOAT
    { M.Float fl }
    [@name float]
  | NULL
    { M.Null }
    [@name null]
  | TRUE
    { M.True }
    [@name true_]
  | FALSE
    { M.False }
    [@name false_]
   

fun_args:
  | arg = expr
    { [ arg ] }
    [@name fun_arg]
  | args = fun_args COMMA arg = expr
    { args @ [arg] }
    [@name fun_args]

tuple:
  | e1 = expr COMMA e2 = expr
    { [e1; e2] }
    [@name t_tuple]
  | t = tuple COMMA e1 = expr
    { t @ [ e1 ] }
    [@name tt_tuple]

in_list:
  | e = expr
    { [ e ] }
    [@name in_list_one]
  | l = in_list COMMA e = expr
    { l @ [ e ] }
    [@name in_list_more]