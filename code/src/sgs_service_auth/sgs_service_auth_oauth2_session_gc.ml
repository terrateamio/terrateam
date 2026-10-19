let src = Logs.Src.create "oauth2_session_gc"

module Logs = (val Logs.src_log src : Logs.LOG)

module Sql = struct
  let delete_expired_sessions_sql = Mql_sql.read [%blob "./sql/delete_expired_oauth2_sessions.sql"]

  let delete_expired_sessions () =
    Pgsql_io.Typed_sql.(sql // Ret.bigint /^ delete_expired_sessions_sql)
end

let kind = "gc_expired_oauth2_sessions"

let run _config _storage db _data =
  let open Abb.Future.Infix_monad in
  Pgsql_io.Prepared_stmt.fetch db (Sql.delete_expired_sessions ()) ~f:Int64.to_int
  >>| function
  | Ok count ->
      let count = count |> CCList.head_opt |> CCOption.get_or ~default:0 in
      Logs.info (fun m -> m "OAUTH2_SESSION_GC : count=%d" count)
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "OAUTH2_SESSION_GC : DB_ERR : %a" Pgsql_io.pp_err err)
