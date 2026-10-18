exception Sql_err of string

(* The repository writes INSERT, UPDATE, DELETE, FOR UPDATE and the schema statements, thus MQL
   needs all its features to read them.  This is not the posture of a query from outside: the
   endpoint that reads a query of a user names no feature at all. *)
let features = Mql.Feature.all

(* [$name] is the parameter syntax of [Pgsql_io.Typed_sql].  MQL keeps each name as it reads it,
   thus [Pgsql_io.Typed_sql.to_query] gives the same number to the same parameter as before. *)
let variables = true

let fail (`Error (pos, src, msg)) =
  let where =
    match pos with
    | Some { Mql.Ast.lnum; offset } -> Printf.sprintf " at line %d, offset %d" lnum offset
    | None -> ""
  in
  raise (Sql_err (Printf.sprintf "MQL cannot read this SQL%s: %s\n%s" where msg src))

(* Render parity, the same rule [Mql_corpus.check] applies to the .sql files: the caller binds
   the text MQL writes, not the text of the file, so the written text must read back as the same
   tree.  Without this, a writer fault on a construct that appears only in one inline literal
   would silently change the SQL that PostgreSQL runs, at a moment no test covers -- the module
   load of a program whose suites are green. *)
let check_render_parity parsed rendered =
  match Mql.Ast.of_string ~variables ~features rendered with
  | Ok reparsed when Mql.Ast.equal parsed reparsed -> Ok rendered
  | Ok _ | Error _ ->
      Error
        (`Error
           ( None,
             rendered,
             "the written text does not read back as the same query -- this is a defect of the \
              writer" ))

let read sql =
  let r =
    let open CCResult.Infix in
    Mql.Ast.of_string ~variables ~features sql
    >>= fun ast -> Mql.Ast.to_string ast >>= check_render_parity ast
  in
  match r with
  | Ok sql -> sql
  | Error err -> fail err

let read_multi_result ?(variables = variables) sql =
  let open CCResult.Infix in
  Mql.Ast.of_string_multi ~variables ~features sql
  >>= fun stmts ->
  CCResult.map_l (fun ast -> Mql.Ast.to_string ast >>= check_render_parity ast) stmts

let read_multi sql =
  match read_multi_result sql with
  | Ok stmts -> stmts
  | Error err -> fail err

let set ?(local = false) ~name value =
  (* The name is spliced into the text unquoted, thus anything but a legal
     identifier is an injection sink waiting for a caller that does not pass a
     constant.  Fail closed here, where the value is still known to be from
     this codebase. *)
  let legal_ident_char = function
    | 'a' .. 'z' | 'A' .. 'Z' | '_' | '0' .. '9' -> true
    | _ -> false
  in
  let legal_ident =
    CCString.length name > 0
    && (match name.[0] with
      | '0' .. '9' -> false
      | _ -> true)
    && CCString.for_all legal_ident_char name
  in
  if not legal_ident then
    raise (Sql_err (Printf.sprintf "the name %S is not a legal identifier" name));
  let stmt =
    Mql_ast.Set_stmt
      {
        local;
        name = { Mql_ast.qualifier = None; base = { Mql_ast.name; quoted = false } };
        value = Mql_ast.String value;
      }
  in
  let r = Mql.Ast.to_string stmt in
  match r with
  | Ok sql -> sql
  | Error err -> fail err

let read_ast sql =
  let r = Mql.Ast.of_string ~variables ~features sql in
  match r with
  | Ok ast -> ast
  | Error err -> fail err

let write ast = Mql.Ast.to_string ast

let write_exn ast =
  let r = Mql.Ast.to_string ast in
  match r with
  | Ok sql -> sql
  | Error err -> fail err

(* [Mql_ast] derives yojson for its whole type group, thus a substitution needs no map over each
   constructor of the tree.  [Variable] is the only constructor of that name in the group, and
   it writes as a two-part list, thus the shape below names it and nothing else.  A round trip
   costs 0.015 ms on a query of 30 lines. *)
let subst_var ~name expr q =
  let target = Mql_ast.expr_to_yojson expr in
  let found = ref false in
  let rec go = function
    | `List [ `String "Variable"; `String v ] when CCString.equal v name ->
        found := true;
        target
    | `List xs -> `List (CCList.map go xs)
    | `Assoc kvs -> `Assoc (CCList.map (fun (k, v) -> (k, go v)) kvs)
    | j -> j
  in
  let j = go (Mql_ast.to_yojson q) in
  if not !found then
    Error (`Error (None, Mql_ast.show q, Printf.sprintf "the query has no $%s" name))
  else
    match Mql_ast.of_yojson j with
    | Ok q -> Ok q
    | Error msg -> Error (`Error (None, Yojson.Safe.to_string j, msg))

(* A CTE body is a query and not an expression, thus a [$name] variable cannot hold its place.  The
   file writes a placeholder query, and this puts the real one in its place. *)
let subst_cte ~name query t =
  let rec go = function
    | Mql_ast.With { materialized; recursive; name = cte; columns; query = body_q; body } ->
        if CCString.equal cte.Mql_ast.name name then
          Some (Mql_ast.With { materialized; recursive; name = cte; columns; query; body })
        else
          CCOption.map
            (fun body ->
              Mql_ast.With { materialized; recursive; name = cte; columns; query = body_q; body })
            (go body)
    | _ -> None
  in
  match go t with
  | Some t -> Ok t
  | None ->
      Error (`Error (None, Mql_ast.show t, Printf.sprintf "the query has no CTE named %s" name))

let with_where ~name q where =
  let open CCResult.Infix in
  (match where with
    | "" -> Ok Mql.Build.true_
    | where -> Mql.Ast.expr_of_string ~variables where)
  >>= fun expr -> subst_var ~name expr q >>= Mql.Ast.to_string
