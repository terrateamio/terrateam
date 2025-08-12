let get config storage services =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user ->
      let run =
        Abbs_future_combinators.List_result.map
          ~f:(function
            | Terrat_vcs_service.Service ((module M), service) -> (
                M.Service.get_user service (Terrat_user.id user)
                >>= function
                | Some _ -> Abb.Future.return (Ok (Some (M.Service.name service)))
                | None -> Abb.Future.return (Ok None)))
          services
        >>= fun vcs -> Abb.Future.return (Ok (CCList.filter_map CCFun.id vcs))
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok vcs ->
          let body =
            { Terrat_api_components.User.id = Uuidm.to_string (Terrat_user.id user); vcs }
            |> Terrat_api_components.User.to_yojson
            |> Yojson.Safe.to_string
          in
          Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
      | Error `Error ->
          Logs.err (fun m -> m "GITHUB_CALLBACK : %a : FAIL" Uuidm.pp (Terrat_user.id user));
          Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_CALLBACK : %a : FAIL : %a"
                Uuidm.pp
                (Terrat_user.id user)
                Pgsql_pool.pp_err
                err);
          Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_CALLBACK : %a : FAIL : %a"
                Uuidm.pp
                (Terrat_user.id user)
                Pgsql_io.pp_err
                err);
          Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx)))
