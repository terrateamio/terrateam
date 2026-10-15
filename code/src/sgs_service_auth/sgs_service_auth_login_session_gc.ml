let src = Logs.Src.create "login_session_gc"

module Logs = (val Logs.src_log src : Logs.LOG)

let kind = "gc_expired_login_sessions"

let run _config _storage db _data =
  let open Abb.Future.Infix_monad in
  Sgs_user_access_token.gc_expired_login_sessions db
  >>| function
  | Ok count -> Logs.info (fun m -> m "LOGIN_SESSION_GC : count=%d" count)
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "LOGIN_SESSION_GC : DB_ERR : %a" Pgsql_io.pp_err err)
