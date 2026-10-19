let select_access_token_sql = Mql_sql.read [%blob "sql/select_gitlab_access_token.sql"]

let select_access_token () =
  Pgsql_io.Typed_sql.(
    sql
    //
    (* access_token *)
    Ret.text
    /^ select_access_token_sql
    /% Var.bigint "installation_id")

let upsert_token_sql = Mql_sql.read [%blob "sql/upsert_gitlab_access_token.sql"]

let upsert_token () =
  Pgsql_io.Typed_sql.(
    sql
    /^ upsert_token_sql
    /% Var.bigint "installation_id"
    /% Var.text "access_token"
    /% Var.uuid "access_token_updated_by"
    /% Var.text "group_name")
