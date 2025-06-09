let src = Logs.Src.create "vcs_service_gitlab_ep_callback"

module Logs = (val Logs.src_log src : Logs.LOG)

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map Pgsql_io.clean_string (Terrat_files_gitlab_sql.read fname))

  let insert_user2 () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      /^ read "insert_user2.sql")

  let select_github_user2 () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* user_id *)
      Ret.uuid
      //
      (* email *)
      Ret.(option text)
      //
      (* name *)
      Ret.(option text)
      //
      (* avatar_url *)
      Ret.text
      /^ read "select_github_user2.sql"
      /% Var.text "username")

  let insert_github_user2 () =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_user2.sql"
      /% Var.(option (text "avatar_url"))
      /% Var.(option (text "email"))
      /% Var.(option (timestamptz "expiration"))
      /% Var.(option (text "name"))
      /% Var.(option (timestamptz "refresh_expiration"))
      /% Var.(option (text "refresh_token"))
      /% Var.text "token"
      /% Var.uuid "user_id"
      /% Var.text "username")
end

let perform_auth config storage code = raise (Failure "nyi")

let get config storage code state ctx =
  let open Abb.Future.Infix_monad in
  perform_auth config storage code
  >>= function
  | Ok user ->
      (* let ctx = Terrat_session.create_user_session user ctx in *)
      raise (Failure "nyi")
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m -> m "FAIL : %s" (Pgsql_pool.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m -> m "FAIL : %s" (Pgsql_io.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
