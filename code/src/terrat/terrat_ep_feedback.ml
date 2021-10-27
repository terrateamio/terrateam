module Process = Abb_process.Make (Abb)

let region = "us-west-2"

module Sql = struct
  let select_installation =
    Pgsql_io.Typed_sql.(
      sql
      // (* login *) Ret.varchar
      // (* html_url *) Ret.varchar
      /^ "select login, html_url from github_installations where id = $id"
      /% Var.bigint "id")

  let insert_installation_feedback =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into installation_feedback (installation_id, user_id, msg) \
          values($installation_id, $user_id, $msg)"
      /% Var.bigint "installation_id"
      /% Var.varchar "user_id"
      /% Var.text "msg")
end

let send_email storage user_id installation_id msg =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.execute db Sql.insert_installation_feedback installation_id user_id msg
      >>= fun () ->
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_installation
        ~f:(fun login url -> (login, url))
        installation_id)
  >>= function
  | (login, url) :: _ ->
      let args =
        Abb_process.args
          "aws"
          [
            "--region";
            region;
            "ses";
            "send-email";
            "--to";
            "feedback@terrateam.io";
            "--from";
            "feedback@terrateam.io";
            "--subject";
            Printf.sprintf "Feedback: %s" user_id;
            "--text";
            Printf.sprintf
              "User: %s\n\n\
               Installation ID: %Ld\n\n\
               Installation Name: %s\n\n\
               Installation URL:%s\n\n\
               Message:\n\n\
               %s"
              user_id
              installation_id
              login
              url
              msg;
          ]
      in
      Process.check_output args >>= fun _ -> Abb.Future.return (Ok ())
  | []                -> assert false

let post config storage github_schema installation_id feedback =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user_id ->
      let open Abb.Future.Infix_monad in
      Terrat_github.verify_user_installation_access
        config
        storage
        github_schema
        installation_id
        user_id
      >>= function
      | Ok () -> (
          send_email storage user_id installation_id feedback.Terrat_data.Request.User_feedback.msg
          >>= function
          | Ok () ->
              Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx))
          | Error (#Abb_process.check_output_err as err) ->
              Logs.err (fun m ->
                  m "FEEDBACK : POST : ERROR : %s" (Abb_process.show_check_output_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m -> m "FEEDBACK : POST : ERROR : DB : %s" (Pgsql_pool.show_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m -> m "FEEDBACK : POST : ERROR : DB : %s" (Pgsql_io.show_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          )
      | Error `Forbidden ->
          Logs.info (fun m -> m "FEEDBACK : POST : FORBIDDEN : %s : %Ld" user_id installation_id);
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "FEEDBACK : POST : ERROR : DB : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "FEEDBACK : POST : ERROR : DB : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Githubc_v3.call_err as err) ->
          Logs.err (fun m ->
              m "FEEDBACK : POST : ERROR : GITHUB : %s" (Githubc_v3.show_call_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Terrat_github.get_access_token_err as err) ->
          Logs.err (fun m ->
              m
                "FEEDBACK : POST : ERROR : GITHUB : %s"
                (Terrat_github.show_get_access_token_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
