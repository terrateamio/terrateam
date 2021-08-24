module Sql = struct
  let select_user_avatar_url =
    Pgsql_io.Typed_sql.(
      sql
      // (* avatar_url *) Ret.varchar
      /^ "select avatar_url from github_users where user_id = $user_id"
      /% Var.varchar "user_id")
end

let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

let get config storage github_schema =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user_id ->
      let open Abb.Future.Infix_monad in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch db Sql.select_user_avatar_url ~f:CCFun.id user_id)
      >>= function
      | Ok (avatar_url :: _)           ->
          let body =
            let open Terrat_data.Response.Whoami in
            { user_id; avatar_url } |> to_yojson |> Yojson.Safe.to_string
          in
          Abb.Future.return
            (Ok
               (Brtl_ctx.set_response
                  (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
                  ctx))
      | Ok []                          ->
          Logs.err (fun m -> m "WHOAMI : ERROR : No avatar URL found");
          assert false
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "WHOAMI : ERROR : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_io.err as err)   ->
          Logs.err (fun m -> m "WHOAMI : ERROR : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
