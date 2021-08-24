let post storage =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user_id ->
      let open Abb.Future.Infix_monad in
      Terrat_session.rem_session storage ctx
      >>= function
      | Ok ctx                         ->
          Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "LOGOUT : ERROR : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_io.err as err)   ->
          Logs.err (fun m -> m "LOGOUT : ERROR : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
