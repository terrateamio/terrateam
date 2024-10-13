type err =
  [ Pgsql_io.err
  | Pgsql_pool.err
  | Terrat_github.Oauth.refresh_err
  ]
[@@deriving show]

module Sql = struct
  let select_user_token () =
    Pgsql_io.Typed_sql.(
      sql
      // (* token *) Ret.text
      // (* expired *) Ret.boolean
      // (* refresh_token *) Ret.text
      /^ "select token, (expiration < now()), refresh_token from github_users where id = $user_id"
      /% Var.uuid "user_id")

  let insert_github_user () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_users (id, token, expiration, refresh_token, refresh_expiration) \
          values ($user_id, $token, $expiration, $refresh_token, $refresh_expiration) on conflict \
          (id) do update set (token, expiration, refresh_token, refresh_expiration) = \
          (excluded.token, excluded.expiration, excluded.refresh_token, \
          excluded.refresh_expiration)"
      /% Var.uuid "user_id"
      /% Var.text "token"
      /% Var.(option (text "refresh_token"))
      /% Var.(option (timestamptz "expiration"))
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
      Terrat_github.Oauth.refresh ~config refresh_token
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
            (Sql.insert_github_user ())
            (Terrat_user.id user)
            oauth.Oauth.access_token
            oauth.Oauth.refresh_token
            expiration
            refresh_expiration
          >>= fun () -> Abb.Future.return (Ok oauth.Oauth.access_token))
  | (token, false, _) :: _ -> Abb.Future.return (Ok token)
