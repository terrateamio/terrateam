type err =
  [ Pgsql_io.err
  | Pgsql_pool.err
  | Terrat_github.Oauth.refresh_err
  ]
[@@deriving show]

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map Pgsql_io.clean_string (Terrat_files_github_sql.read fname))

  let select_user_token () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* token *)
      Ret.text
      //
      (* expired *)
      Ret.boolean
      //
      (* refresh_token *)
      Ret.text
      /^ read "select_github_user2_tokens.sql"
      /% Var.uuid "user_id")

  let update_github_user2_tokens () =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "update_github_user2_tokens.sql"
      /% Var.uuid "user_id"
      /% Var.text "token"
      /% Var.(option (timestamptz "expiration"))
      /% Var.(option (text "refresh_token"))
      /% Var.(option (timestamptz "refresh_expiration")))
end

let get_token config storage user =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.fetch
        db
        (Sql.select_user_token ())
        ~f:(fun token expired refresh_token -> (token, expired, refresh_token))
        (Terrat_user.id user))
  >>= function
  | [] -> assert false
  | (_, true, refresh_token) :: _ ->
      let module Oauth = Terrat_github.Oauth.Response in
      Terrat_github.Oauth.refresh
        ~config:(Terrat_vcs_service_github_provider.Api.Config.vcs_config config)
        refresh_token
      >>= fun oauth ->
      Abbs_future_combinators.to_result (Abb.Sys.time ())
      >>= fun now ->
      let expiration =
        CCOption.map
          (fun exp -> ISO8601.Permissive.string_of_datetime (now +. CCFloat.of_int exp))
          oauth.Oauth.expires_in
      in
      let refresh_expiration =
        CCOption.map
          (fun exp -> ISO8601.Permissive.string_of_datetime (now +. CCFloat.of_int exp))
          oauth.Oauth.refresh_token_expires_in
      in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.execute
            db
            (Sql.update_github_user2_tokens ())
            (Terrat_user.id user)
            oauth.Oauth.access_token
            expiration
            oauth.Oauth.refresh_token
            refresh_expiration
          >>= fun () -> Abb.Future.return (Ok oauth.Oauth.access_token))
  | (token, false, _) :: _ -> Abb.Future.return (Ok token)
