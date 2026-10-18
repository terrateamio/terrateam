module Sql = struct
  let select_system_setting_sql = Mql_sql.read [%blob "./sql/select_system_setting.sql"]

  let select_system_setting () =
    Pgsql_io.Typed_sql.(sql // Ret.jsonb /^ select_system_setting_sql /% Var.text "key")

  let upsert_system_setting_sql = Mql_sql.read [%blob "./sql/upsert_system_setting.sql"]

  let upsert_system_setting () =
    Pgsql_io.Typed_sql.(sql /^ upsert_system_setting_sql /% Var.text "key" /% Var.json "value")
end

let fetch key db =
  let open Abbs_fc.Infix_result_monad in
  Pgsql_io.Prepared_stmt.fetch db (Sql.select_system_setting ()) ~f:CCFun.id key
  >>| fun rows -> CCList.head_opt rows

let store key value db = Pgsql_io.Prepared_stmt.execute db (Sql.upsert_system_setting ()) key value
