(* Each template wraps the expression so that its value type does not matter
   to the query around it. *)
let positions =
  [
    ("select list", fun e -> "select " ^ e ^ " from states");
    ("where", fun e -> "select id from states where " ^ e ^ " is not null");
    ("join on", fun e -> "select states.id from states join resources on " ^ e ^ " is not null");
    ("order by", fun e -> "select id from states order by " ^ e);
    ("limit", fun e -> "select id from states limit " ^ e);
    ( "subquery",
      fun e ->
        "select id from states where id in (select id from states where " ^ e ^ " is not null)" );
    ("cte body", fun e -> "with c as (select " ^ e ^ " as v from states) select v from c");
    ( "left branch of a set operation",
      fun e -> "select id from states where " ^ e ^ " is not null union select id from states" );
    ( "right branch of a set operation",
      fun e -> "select id from states union select id from states where " ^ e ^ " is not null" );
    ("case", fun e -> "select case when " ^ e ^ " is not null then 1 else 0 end from states");
    ("array constructor", fun e -> "select array[" ^ e ^ "] from states");
    ("argument of an allowed function", fun e -> "select coalesce(" ^ e ^ ") from states");
  ]

let forbidden_functions =
  [
    ("query_to_xml", "query_to_xml('select * from tenant_users', true, true, '')");
    ( "query_to_xml_and_xmlschema",
      "query_to_xml_and_xmlschema('select * from tenant_users', true, true, '')" );
    ("table_to_xml", "table_to_xml('tenant_users', true, true, '')");
    ("xpath", "xpath('/a', '<a/>')");
    ("to_regclass", "to_regclass('tenant_users')");
    ("current_setting", "current_setting('search_path')");
    ("set_config", "set_config('search_path', 'public', true)");
    ("pg_read_file", "pg_read_file('/etc/passwd')");
    ("pg_ls_dir", "pg_ls_dir('.')");
    ("lo_import", "lo_import('/etc/passwd')");
    ("dblink", "dblink('dbname=stategraph', 'select * from tenant_users')");
    ("format", "format('select * from %I', 'tenant_users')");
    ("quote_ident", "quote_ident('tenant_users')");
    ("row_to_json", "row_to_json(states)");
    ("jsonb_populate_record", "jsonb_populate_record(null, '{}')");
    ("json_populate_record", "json_populate_record(null, '{}')");
    ("pg_get_viewdef", "pg_get_viewdef('pg_roles')");
    ("has_table_privilege", "has_table_privilege('tenant_users', 'select')");
    ("nextval", "nextval('tenant_users_id_seq')");
    ("pg_sleep", "pg_sleep(10)");
  ]

let forbidden_casts =
  [
    ("regclass", "'tenant_users'::regclass");
    ("regproc", "'pg_read_file'::regproc");
    ("regprocedure", "'pg_read_file(text)'::regprocedure");
    ("regtype", "'text'::regtype");
    ("regnamespace", "'pg_catalog'::regnamespace");
    ("oid", "'1'::oid");
    ("xml", "'<a/>'::xml");
  ]

let name_tricks =
  [
    ("table name in upper case", "select * from TENANT_USERS");
    ("table name in mixed case", "select * from Tenant_Users");
    ("table name as a quoted identifier", "select * from \"tenant_users\"");
    ("table name as an upper case quoted identifier", "select * from \"TENANT_USERS\"");
    ("Unicode-escape identifier", "select * from U&\"tenant\\005fusers\"");
    ("Unicode-escape identifier of a schema table", "select * from U&\"st\\0061tes\"");
    ("comment in a qualified name", "select * from pg_catalog/**/.pg_authid");
    ("whitespace in a qualified name", "select * from pg_catalog . pg_authid");
    ("whitespace in a qualified name of a schema table", "select * from public . states");
    ("OPERATOR(pg_catalog.=)", "select id from states where 1 OPERATOR(pg_catalog.=) 1");
    ("TABLE of a table outside the schema", "TABLE tenant_users");
    ("TABLE of a schema table", "TABLE states");
    ("ONLY", "select * from ONLY states");
    ("ROWS FROM", "select * from rows from (pg_ls_dir('.'))");
    ("function call in FROM", "select * from pg_ls_dir('.')");
    ("function call in FROM with LATERAL", "select * from states, lateral pg_ls_dir('.')");
    ( "function call in FROM with a LATERAL join",
      "select * from states cross join lateral pg_ls_dir('.') as f" );
  ]

let default_func_allow_list =
  [
    "coalesce";
    "nullif";
    "greatest";
    "least";
    "count";
    "sum";
    "avg";
    "min";
    "max";
    "bool_and";
    "bool_or";
    "string_agg";
    "array_agg";
    "json_agg";
    "jsonb_agg";
    "lower";
    "upper";
    "length";
    "trim";
    "ltrim";
    "rtrim";
    "substr";
    "replace";
    "split_part";
    "strpos";
    "starts_with";
    "concat";
    "concat_ws";
    "regexp_replace";
    "to_char";
    "abs";
    "ceil";
    "floor";
    "round";
    "trunc";
    "to_jsonb";
    "json_build_object";
    "jsonb_build_object";
    "json_build_array";
    "jsonb_build_array";
    "json_array_length";
    "jsonb_array_length";
    "json_typeof";
    "jsonb_typeof";
    "jsonb_extract_path_text";
    "jsonb_pretty";
    "array_length";
    "cardinality";
    "array_to_string";
    "now";
    "date_trunc";
    "date_part";
    "age";
  ]

let default_cast_allow_list =
  [
    "bigint";
    "bool";
    "boolean";
    "integer";
    "jsonb";
    "real";
    "smallint";
    "text";
    "timestamptz";
    "uuid";
  ]

let sql = "select * from tenant_users"

(* A text function gets the three kinds of names the RFD lists: a table name,
   a column name and a SQL statement. *)
let text_cases f =
  CCList.map
    (fun arg -> "select " ^ f ^ "('" ^ arg ^ "') from states")
    [ "tenant_users"; "tenant_users.user_id"; sql ]

let allowed_function_cases =
  [
    ("coalesce", text_cases "coalesce");
    ("nullif", [ "select nullif('tenant_users', '" ^ sql ^ "') from states" ]);
    ("greatest", [ "select greatest('tenant_users', '" ^ sql ^ "') from states" ]);
    ("least", [ "select least('tenant_users', '" ^ sql ^ "') from states" ]);
    ("count", [ "select count('tenant_users') from states" ]);
    ("sum", [ "select sum(length('" ^ sql ^ "')) from states" ]);
    ("avg", [ "select avg(length('" ^ sql ^ "')) from states" ]);
    ("min", text_cases "min");
    ("max", text_cases "max");
    ("bool_and", [ "select bool_and('tenant_users' = '" ^ sql ^ "') from states" ]);
    ("bool_or", [ "select bool_or('tenant_users' = '" ^ sql ^ "') from states" ]);
    ("string_agg", [ "select string_agg('" ^ sql ^ "', 'tenant_users') from states" ]);
    ("array_agg", text_cases "array_agg");
    ("json_agg", text_cases "json_agg");
    ("jsonb_agg", text_cases "jsonb_agg");
    ("lower", text_cases "lower");
    ("upper", text_cases "upper");
    ("length", text_cases "length");
    ("trim", text_cases "trim");
    ("ltrim", text_cases "ltrim");
    ("rtrim", text_cases "rtrim");
    ("substr", [ "select substr('" ^ sql ^ "', 1, 100) from states" ]);
    ("replace", [ "select replace('" ^ sql ^ "', 'tenant_users', 'states') from states" ]);
    ("split_part", [ "select split_part('tenant_users.user_id', '.', 2) from states" ]);
    ("strpos", [ "select strpos('" ^ sql ^ "', 'tenant_users') from states" ]);
    ("starts_with", [ "select starts_with('" ^ sql ^ "', 'select') from states" ]);
    ("concat", [ "select concat('select * from ', 'tenant_users') from states" ]);
    ("concat_ws", [ "select concat_ws(' ', 'select', '*', 'from', 'tenant_users') from states" ]);
    ("regexp_replace", [ "select regexp_replace('" ^ sql ^ "', 'tenant', 'x') from states" ]);
    ("to_char", [ "select to_char(created_at, 'tenant_users') from states" ]);
    ("abs", [ "select abs(length('tenant_users')) from states" ]);
    ("ceil", [ "select ceil(length('tenant_users')) from states" ]);
    ("floor", [ "select floor(length('tenant_users')) from states" ]);
    ("round", [ "select round(length('tenant_users')) from states" ]);
    ("trunc", [ "select trunc(length('tenant_users')) from states" ]);
    ("to_jsonb", [ "select to_jsonb('" ^ sql ^ "'::text) from states" ]);
    ("json_build_object", [ "select json_build_object('tenant_users', '" ^ sql ^ "') from states" ]);
    ( "jsonb_build_object",
      [ "select jsonb_build_object('tenant_users', '" ^ sql ^ "') from states" ] );
    ("json_build_array", [ "select json_build_array('tenant_users', '" ^ sql ^ "') from states" ]);
    ("jsonb_build_array", [ "select jsonb_build_array('tenant_users', '" ^ sql ^ "') from states" ]);
    ( "json_array_length",
      [ "select json_array_length(json_build_array('" ^ sql ^ "')) from states" ] );
    ( "jsonb_array_length",
      [ "select jsonb_array_length(jsonb_build_array('" ^ sql ^ "')) from states" ] );
    ("json_typeof", [ "select json_typeof(json_build_object('a', '" ^ sql ^ "')) from states" ]);
    ("jsonb_typeof", [ "select jsonb_typeof(jsonb_build_object('a', '" ^ sql ^ "')) from states" ]);
    ( "jsonb_extract_path_text",
      [
        "select jsonb_extract_path_text(jsonb_build_object('tenant_users', '"
        ^ sql
        ^ "'), 'tenant_users') from states";
      ] );
    ( "jsonb_pretty",
      [ "select jsonb_pretty(jsonb_build_object('tenant_users', '" ^ sql ^ "')) from states" ] );
    (* MQL refuses an array constructor, thus these read the [text[]] column
       [instances.dependencies]. *)
    ("array_length", [ "select array_length(dependencies, 1) from instances" ]);
    ("cardinality", [ "select cardinality(dependencies) from instances" ]);
    ("array_to_string", [ "select array_to_string(dependencies, '" ^ sql ^ "') from instances" ]);
    ("now", [ "select now() from states" ]);
    ("date_trunc", [ "select date_trunc('day', created_at) from states" ]);
    ("date_part", [ "select date_part('epoch', created_at) from states" ]);
    ("age", [ "select age(created_at) from states" ]);
  ]

(* The queries that must be refused: the forbidden functions and casts in each position, then each
   name trick.  The allowed-function queries are not here -- {!Mql_to_pgsql.of_mql} accepts those,
   which is the point of them. *)
let refusal_queries () =
  let in_positions kind exprs =
    CCList.flat_map
      (fun (name, expr) ->
        CCList.map
          (fun (position, template) -> (kind ^ " " ^ name ^ " in " ^ position, template expr))
          positions)
      exprs
  in
  in_positions "function" forbidden_functions
  @ in_positions "cast" forbidden_casts
  @ CCList.map (fun (name, q) -> ("name trick: " ^ name, q)) name_tricks

let all_queries () =
  let in_positions kind exprs =
    CCList.flat_map
      (fun (name, expr) ->
        CCList.map
          (fun (position, template) -> (kind ^ " " ^ name ^ " in " ^ position, template expr))
          positions)
      exprs
  in
  in_positions "function" forbidden_functions
  @ in_positions "cast" forbidden_casts
  @ CCList.map (fun (name, q) -> ("name trick: " ^ name, q)) name_tricks
  @ CCList.flat_map
      (fun (name, qs) -> CCList.map (fun q -> ("allowed function " ^ name, q)) qs)
      allowed_function_cases

(* What happens to one query of the corpus, and which of those outcomes is a
   refusal.  The unit suite of [mql_to_pgsql] and the tests of the MQL endpoint
   both run the queries of this corpus, so the rules live here: one copy cannot
   drift away from the other.  An audit error is not a refusal -- the audit
   finds only what a guard of the rewrite did not refuse, thus in a test it
   shows a missing guard -- and that rule is the easy one to get wrong, which
   is the other reason it holds one copy. *)
type outcome =
  | Parse_err of Mql.Ast.err
  | Of_mql_err of Mql_to_pgsql.err
  | Accepted

let show_outcome = function
  | Parse_err err -> "parse error " ^ Mql.Ast.show_err err
  | Of_mql_err err -> Mql_to_pgsql.show_err err
  | Accepted -> "accepted"

let outcome ?(variables = false) ?(schema = Mql_to_pgsql.Schema.make []) query =
  match Mql.Ast.of_string ~variables query with
  | Error err -> Parse_err err
  | Ok ast -> (
      match
        Mql_to_pgsql.of_mql
          ~func_allow_list:Mql_to_pgsql.default_func_allow_list
          ~cast_allow_list:Mql_to_pgsql.default_cast_allow_list
          ~schema
          ast
      with
      | Ok _ -> Accepted
      | Error err -> Of_mql_err err)

let accepted = function
  | Accepted -> true
  | Parse_err _ | Of_mql_err _ -> false

let refused = function
  | Accepted -> false
  | Parse_err _ -> true
  | Of_mql_err #Mql_to_pgsql.audit_err -> false
  | Of_mql_err _ -> true

let of_mql_err expected = function
  | Of_mql_err err -> Mql_to_pgsql.equal_err expected err
  | Parse_err _ | Accepted -> false

let func_access_err = function
  | Of_mql_err (`Func_access_err _) -> true
  | _ -> false

let cast_err = function
  | Of_mql_err (`Cast_err _) -> true
  | _ -> false

let unknown_column_err = function
  | Of_mql_err (`Unknown_column_err _) -> true
  | _ -> false

let construct_not_allowed_err = function
  | Of_mql_err (`Construct_not_allowed_err _) -> true
  | _ -> false
