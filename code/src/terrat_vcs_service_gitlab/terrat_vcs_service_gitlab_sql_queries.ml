let read fname =
  CCOption.get_exn_or
    fname
    (CCOption.map Pgsql_io.clean_string (Terrat_files_gitlab_sql.read fname))

let select_access_token () =
  Pgsql_io.Typed_sql.(
    sql
    //
    (* access_token *)
    Ret.text
    /^ read "select_gitlab_access_token.sql"
    /% Var.bigint "installation_id")

let upsert_token () =
  Pgsql_io.Typed_sql.(
    sql
    /^ read "upsert_gitlab_access_token.sql"
    /% Var.bigint "installation_id"
    /% Var.text "access_token"
    /% Var.uuid "access_token_updated_by"
    /% Var.text "group_name")
