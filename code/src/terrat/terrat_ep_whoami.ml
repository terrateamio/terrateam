let get config storage =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>| fun user ->
      let body =
        Terrat_api_components.User.
          {
            id = Uuidm.to_string (Terrat_user.id user);
            email = Terrat_user.email user;
            name = Terrat_user.name user;
            avatar_url = Terrat_user.avatar_url user;
          }
        |> Terrat_api_components.User.to_yojson
        |> Yojson.Safe.to_string
      in
      Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)
