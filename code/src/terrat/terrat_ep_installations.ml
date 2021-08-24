let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

let get config storage github_schema =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user_id ->
      let open Abb.Future.Infix_monad in
      Terrat_github.get_user_installations config storage github_schema user_id
      >>= function
      | Ok installations ->
          let body =
            let open Terrat_data.Response.Installation_list in
            { next = None; prev = None; results = installations }
            |> to_yojson
            |> Yojson.Safe.to_string
          in
          Abb.Future.return
            (Ok
               (Brtl_ctx.set_response
                  (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
                  ctx))
      | Error (#Terrat_github.get_user_installations_err as err) ->
          Logs.err (fun m ->
              m
                "INSTALLATIONS : GET : ERROR : %s"
                (Terrat_github.show_get_user_installations_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
