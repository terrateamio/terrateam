module Gh = Githubc_v3

module Sql = struct
  let read_sql fname = CCOpt.get_exn_or fname (Terrat_files_github.read fname)

  let insert_github_users =
    Pgsql_io.Typed_sql.(
      sql
      /^ read_sql "insert_github_users.sql"
      /% Var.varchar "user_id"
      /% Var.(option (varchar "email"))
      /% Var.varchar "avatar_url"
      /% Var.varchar "token"
      /% Var.(option (varchar "refresh_token"))
      /% Var.(option (timestamptz "expiration"))
      /% Var.(option (timestamptz "refresh_expiration")))
end

let perform_auth storage github_schema client_id client_secret code =
  let open Abbs_future_combinators.Infix_result_monad in
  Gh.oauth_authorize ~user_agent:"Terrateam" ~client_id ~client_secret code
  >>= fun oauth_access_token ->
  let token = Gh.Response.Oauth_access_token.access_token oauth_access_token in
  Gh.create github_schema (`Token token)
  >>= fun gh ->
  Gh.call gh (Gh.current_user gh)
  >>= fun current_user ->
  Gh.collect_all gh (Gh.user_public_emails gh)
  >>= fun public_emails ->
  Abbs_future_combinators.to_result (Abb.Sys.time ())
  >>= fun now ->
  let current_user = Gh.Response.value current_user in
  let user_id = Gh.Response.Current_user.login current_user in
  let email =
    public_emails
    |> CCList.filter Gh.Response.User_public_email.primary
    |> CCList.head_opt
    |> CCOpt.map Gh.Response.User_public_email.email
  in
  let avatar_url = Uri.to_string (Gh.Response.Current_user.avatar_url current_user) in
  let expiration =
    CCOpt.map
      (fun exp -> ISO8601.Permissive.string_of_datetime (now +. CCFloat.of_int exp))
      (Gh.Response.Oauth_access_token.expires_in oauth_access_token)
  in
  let refresh_expiration =
    CCOpt.map
      (fun exp -> ISO8601.Permissive.string_of_datetime (now +. CCFloat.of_int exp))
      (Gh.Response.Oauth_access_token.refresh_token_expires_in oauth_access_token)
  in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.execute
        db
        Sql.insert_github_users
        user_id
        email
        avatar_url
        token
        (Gh.Response.Oauth_access_token.refresh_token oauth_access_token)
        expiration
        refresh_expiration)
  >>= fun () -> Abb.Future.return (Ok user_id)

let get config storage github_schema code installation_id ctx =
  let open Abb.Future.Infix_monad in
  perform_auth
    storage
    github_schema
    (Terrat_config.github_app_client_id config)
    (Terrat_config.github_app_client_secret config)
    code
  >>= function
  | Ok user_id                     ->
      let ctx = Terrat_session.create_user_session user_id ctx in
      let uri =
        Uri.to_string
          (Uri.make
             ~path:"/"
             ~query:[ ("installation_id", [ Int64.to_string installation_id ]) ]
             ())
      in
      let headers = Cohttp.Header.of_list [ ("location", uri) ] in
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~headers ~status:`See_other "") ctx)
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m -> m "GITHUB_CALLBACK : FAIL : %s" (Pgsql_pool.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (#Pgsql_io.err as err)   ->
      Logs.err (fun m -> m "GITHUB_CALLBACK : FAIL : %s" (Pgsql_io.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | Error (#Gh.call_err as err)    ->
      Logs.err (fun m -> m "GITHUB_CALLBACK : FAIL : %s" (Gh.show_call_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
