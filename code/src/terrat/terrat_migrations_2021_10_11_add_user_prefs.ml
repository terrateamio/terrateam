module Sql = struct
  let select_users_without_email =
    Pgsql_io.Typed_sql.(
      sql // (* user_id *) Ret.varchar /^ "select user_id from github_users where email is null")

  let update_user_email =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_users set email = $email where user_id = $user_id"
      /% Var.varchar "user_id"
      /% Var.varchar "email")
end

let run' config storage =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.fetch db Sql.select_users_without_email ~f:CCFun.id
      >>= fun users ->
      Githubc_v3.Schema.create ()
      >>= fun github_schema ->
      Abbs_future_combinators.List_result.iter
        ~f:(fun user_id ->
          Terrat_github.get_access_token
            storage
            (Terrat_config.github_app_client_id config)
            (Terrat_config.github_app_client_secret config)
            user_id
          >>= fun token ->
          Terrat_github.create github_schema (`Token token)
          >>= fun gh ->
          Githubc_v3.call gh (Githubc_v3.current_user gh)
          >>= fun current_user ->
          let current_user = Githubc_v3.Response.value current_user in
          match Githubc_v3.Response.Current_user.email current_user with
          | Some email -> Pgsql_io.Prepared_stmt.execute db Sql.update_user_email user_id email
          | None -> Abb.Future.return (Ok ()))
        users)

let run (config, storage) =
  let open Abb.Future.Infix_monad in
  run' config storage
  >>= function
  | Ok () -> Abb.Future.return (Ok ())
  | Error (#Pgsql_pool.err | #Pgsql_io.err) as err -> Abb.Future.return err
  | Error (#Terrat_github.get_access_token_err as err) ->
      Logs.err (fun m ->
          m "MIGRATION : ADD_EMAIL : ERROR : %s" (Terrat_github.show_get_access_token_err err));
      failwith "migration failed"
  | Error (#Githubc_v3.call_err as err) ->
      Logs.err (fun m -> m "MIGRATION : ADD_EMAIL : ERROR : %s" (Githubc_v3.show_call_err err));
      failwith "Migration failed"
