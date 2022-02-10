let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

module Prefs = struct
  module Sql = struct
    let read fname = CCOpt.get_exn_or fname (Terrat_files_github.read fname)

    let select_user_prefs =
      Pgsql_io.Typed_sql.(
        sql
        // (* receive marketing emails *) Ret.boolean
        // (* email *) Ret.(option varchar)
        /^ read "select_user_prefs.sql"
        /% Var.varchar "user_id")

    let update_user_prefs =
      Pgsql_io.Typed_sql.(
        sql
        /^ read "update_user_prefs.sql"
        /% Var.boolean "receive_marketing_emails"
        /% Var.varchar "user_id")
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
              Sql.select_user_prefs
              ~f:(fun receive_marketing_emails email ->
                Terrat_data.Response.User_prefs.{ receive_marketing_emails; email })
              user_id)
        >>= function
        | Ok (prefs :: _) ->
            let body =
              prefs |> Terrat_data.Response.User_prefs.to_yojson |> Yojson.Safe.to_string
            in
            Abb.Future.return
              (Ok
                 (Brtl_ctx.set_response
                    (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
                    ctx))
        | Ok [] ->
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m -> m "USER_PREFS : GET : ERROR : %s" (Pgsql_pool.show_err err));
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m -> m "USER_PREFS : GET : ERROR : %s" (Pgsql_io.show_err err));
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))

  let perform_put storage user_id update ctx =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        match update.Terrat_data.Request.User_prefs.receive_marketing_emails with
        | Some receive_marketing_emails ->
            Pgsql_io.Prepared_stmt.execute db Sql.update_user_prefs receive_marketing_emails user_id
            >>= fun () ->
            Pgsql_io.Prepared_stmt.fetch
              db
              Sql.select_user_prefs
              ~f:(fun receive_marketing_emails email ->
                Terrat_data.Response.User_prefs.{ receive_marketing_emails; email })
              user_id
        | None ->
            Pgsql_io.Prepared_stmt.fetch
              db
              Sql.select_user_prefs
              ~f:(fun receive_marketing_emails email ->
                Terrat_data.Response.User_prefs.{ receive_marketing_emails; email })
              user_id)

  let put storage update =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user_id ->
        let open Abb.Future.Infix_monad in
        perform_put storage user_id update ctx
        >>= function
        | Ok (prefs :: _) ->
            let body =
              prefs |> Terrat_data.Response.User_prefs.to_yojson |> Yojson.Safe.to_string
            in
            Abb.Future.return
              (Ok
                 (Brtl_ctx.set_response
                    (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
                    ctx))
        | Ok [] ->
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m -> m "USER_PREFS : PUT : ERROR : %s" (Pgsql_pool.show_err err));
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m -> m "USER_PREFS : PUT : ERROR : %s" (Pgsql_io.show_err err));
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end
