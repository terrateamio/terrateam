let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

module Sql = struct
  let read fname = CCOpt.get_exn_or fname (Terrat_files_github.read fname)

  let select_user_sessions =
    Pgsql_io.Typed_sql.(
      sql
      // (* created_at *) Ret.varchar
      // (* user_agent *) Ret.varchar
      /^ read "select_user_sessions.sql"
      /% Var.varchar "user_id")

  let delete_user_sessions =
    Pgsql_io.Typed_sql.(sql /^ read "delete_user_sessions.sql" /% Var.varchar "user_id")
end

let get storage =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user_id ->
      let open Abb.Future.Infix_monad in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_user_sessions
            ~f:(fun created_at user_agent ->
              Terrat_data.Response.Session.{ created_at; user_agent })
            user_id)
      >>= function
      | Ok sessions ->
          let body =
            Terrat_data.Response.Session_list.(
              { results = sessions; next = None; prev = None } |> to_yojson |> Yojson.Safe.to_string)
          in
          Abb.Future.return
            (Ok
               (Brtl_ctx.set_response
                  (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
                  ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "SESSIONS : GET : ERROR : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "SESSIONS : GET : ERROR : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))

let delete storage =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user_id ->
      let open Abb.Future.Infix_monad in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.execute db Sql.delete_user_sessions user_id)
      >>= function
      | Ok () ->
          Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "SESSIONS : DELETE : ERROR : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "SESSIONS : DELETE : ERROR : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
