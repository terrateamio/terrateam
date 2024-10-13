module Sql = struct
  let select_github_unexpired_refresh_token =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.uuid
      /^ "select id from github_users where id = $id and now() < refresh_expiration"
      /% Var.uuid "id")
end

let get config storage =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user ->
      let open Abb.Future.Infix_monad in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_github_unexpired_refresh_token
            ~f:CCFun.id
            (Terrat_user.id user))
      >>= function
      | Ok [] -> (
          Terrat_session.rem_session storage ctx
          >>= function
          | Ok ctx -> Abb.Future.return (Error (Brtl_ctx.set_response `Forbidden ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m -> m "GITHUB_CALLBACK : FAIL : %s" (Pgsql_pool.show_err err));
              Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m -> m "GITHUB_CALLBACK : FAIL : %s" (Pgsql_io.show_err err));
              Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx)))
      | Ok (_ :: _) ->
          let body =
            {
              Terrat_api_components.User.id = Uuidm.to_string (Terrat_user.id user);
              email = Terrat_user.email user;
              name = Terrat_user.name user;
              avatar_url = Terrat_user.avatar_url user;
            }
            |> Terrat_api_components.User.to_yojson
            |> Yojson.Safe.to_string
          in
          Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "GITHUB_CALLBACK : FAIL : %s" (Pgsql_pool.show_err err));
          Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GITHUB_CALLBACK : FAIL : %s" (Pgsql_io.show_err err));
          Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx)))
