let get config storage =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>| fun user ->
      let body = user |> Terrat_api_components.User.to_yojson |> Yojson.Safe.to_string in
      Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)
