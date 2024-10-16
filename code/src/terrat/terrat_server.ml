module Make
    (Terratc : Terratc_intf.S
                 with type Github.Client.t = Terrat_github_evaluator3.S.Client.t
                  and type Github.Account.t = Terrat_github_evaluator3.S.Account.t
                  and type Github.Repo.t = Terrat_github_evaluator3.S.Repo.t
                  and type Github.Remote_repo.t = Terrat_github_evaluator3.S.Remote_repo.t
                  and type Github.Ref.t = Terrat_github_evaluator3.S.Ref.t) =
struct
  module Github_evaluator = Terrat_github_evaluator3.Make (Terratc)
  module Github_events = Terrat_ep_github_events3.Make (Terratc)
  module Github_work_manifest = Terrat_ep_github_work_manifest3.Make (Terratc)

  module Rt = struct
    let api () = Brtl_rtng.Route.(rel / "api")
    let api_404 () = Brtl_rtng.Route.(api () /% Path.any)
    let api_v1 () = Brtl_rtng.Route.(api () / "v1")
    let whoami () = Brtl_rtng.Route.(api_v1 () / "whoami")
    let github_client_id () = Brtl_rtng.Route.(api_v1 () / "github" / "client_id")
    let server_config () = Brtl_rtng.Route.(api_v1 () / "server" / "config")
    let work_manifest_root base = Brtl_rtng.Route.(base () / "work-manifests")
    let work_manifest base = Brtl_rtng.Route.(work_manifest_root base /% Path.ud Uuidm.of_string)

    let work_manifest_initiate base =
      Brtl_rtng.Route.(
        work_manifest base
        / "initiate"
        /* Body.decode ~json:Terrat_api_work_manifest.Initiate.Request_body.of_yojson ())

    let work_manifest_plan base =
      Brtl_rtng.Route.(
        work_manifest base
        / "plans"
        /* Body.decode ~json:Terrat_api_work_manifest.Plan_create.Request_body.of_yojson ())

    let work_manifest_results base =
      Brtl_rtng.Route.(
        work_manifest base
        /* Body.decode ~json:Terrat_api_work_manifest.Results.Request_body.of_yojson ())

    let work_manifest_access_token base = Brtl_rtng.Route.(work_manifest base / "access-token")
    let github () = Brtl_rtng.Route.(api () / "github" / "v1")
    let github_events () = Brtl_rtng.Route.(github () / "events")
    let github_work_manifest_plan () = work_manifest_plan github
    let github_work_manifest_initiate () = work_manifest_initiate github
    let github_work_manifest_results () = work_manifest_results github
    let github_work_manifest_access_token () = work_manifest_access_token github

    let github_get_work_manifest_plan () =
      Brtl_rtng.Route.(
        work_manifest github / "plans" /? Query.string "path" /? Query.string "workspace")

    let github_callback () =
      Brtl_rtng.Route.(
        github ()
        / "callback"
        /? Query.string "code"
        /? Query.(option (ud "installation_id" (CCOption.wrap Int64.of_string))))

    let health_check () = Brtl_rtng.Route.(rel / "health")
    let infracost () = Brtl_rtng.Route.(api () / "github" / "infracost" /% Path.any)
    let metrics () = Brtl_rtng.Route.(rel / "metrics")

    (* Admin interface *)
    let admin_rt () = Brtl_rtng.Route.(api_v1 () / "admin")
    let admin_drift_list_rt () = Brtl_rtng.Route.(admin_rt () / "drifts")

    (* User API *)
    let user_api_rt () = Brtl_rtng.Route.(api_v1 () / "user")
    let user_installations_rt () = Brtl_rtng.Route.(user_api_rt () / "installations")

    (* Installations API *)
    let installation_api_rt () = Brtl_rtng.Route.(api_v1 () / "installations")

    let installation_work_manifests_rt () =
      Brtl_rtng.Route.(
        installation_api_rt ()
        /% Path.int
        / "work-manifests"
        /? Query.(option (string "q"))
        /? Query.(option (string "tz"))
        /? Query.(
             option
               (ud_array
                  "page"
                  Brtl_ep_paginate.Param.(of_param Typ.(tuple (string, ud' Uuidm.of_string)))))
        /? Query.(option_default 20 (Query.int "limit")))

    let installation_work_manifest_outputs_rt () =
      Brtl_rtng.Route.(
        installation_api_rt ()
        /% Path.int
        / "work-manifests"
        /% Path.ud Uuidm.of_string
        / "outputs"
        /? Query.(option (string "q"))
        /? Query.(option (string "tz"))
        /? Query.(option (ud_array "page" Brtl_ep_paginate.Param.(of_param Typ.int)))
        /? Query.(option_default 20 (Query.int "limit")))

    let installation_dirspaces_rt () =
      Brtl_rtng.Route.(
        installation_api_rt ()
        /% Path.int
        / "dirspaces"
        /? Query.(option (string "q"))
        /? Query.(option (string "tz"))
        /? Query.(
             option
               (ud_array
                  "page"
                  Brtl_ep_paginate.Param.(
                    of_param Typ.(tuple4 (string, string, string, ud' Uuidm.of_string)))))
        /? Query.(option_default 20 (Query.int "limit")))

    let installation_pull_requests_manifests_rt () =
      Brtl_rtng.Route.(
        installation_api_rt ()
        /% Path.int
        / "pull-requests"
        /? Query.(option (int "pr"))
        /? Query.(
             option
               (ud_array "page" Brtl_ep_paginate.Param.(of_param Typ.(ud' CCInt64.of_string_opt))))
        /? Query.(option_default 20 (Query.int "limit")))

    let installation_repos_rt () =
      Brtl_rtng.Route.(
        installation_api_rt ()
        /% Path.int
        / "repos"
        /? Query.(option (ud_array "page" Brtl_ep_paginate.Param.(of_param Typ.string)))
        /? Query.(option_default 20 (int "limit")))

    let installation_repos_refresh_rt () =
      Brtl_rtng.Route.(installation_api_rt () /% Path.int / "repos" / "refresh")

    (* Tasks API *)
    let tasks_api_rt () = Brtl_rtng.Route.(api_v1 () / "tasks")
    let task_rt () = Brtl_rtng.Route.(tasks_api_rt () /% Path.ud Uuidm.of_string)
  end

  let response_404 ctx =
    Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)

  let maybe_add_admin_routes config storage =
    (* Very important, we only want to add these endpoints if the admin token is
       set.  The admin token is really only meant for debugging purposes. *)
    match Terrat_config.admin_token config with
    | Some token ->
        Brtl_rtng.Route.
          [
            (`GET, Rt.admin_drift_list_rt () --> Terrat_ep_admin.Drift.List.get token config storage);
          ]
    | None -> []

  let rtng config storage =
    Brtl_rtng.create
      ~default:(fun ctx ->
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx))
      (maybe_add_admin_routes config storage
      @ Brtl_rtng.Route.
          [
            (* Ops *)
            (`GET, Rt.health_check () --> Terrat_ep_health_check.get storage);
            (`GET, Rt.metrics () --> Terrat_ep_metrics.get);
            (* Tasks *)
            (`GET, Rt.task_rt () --> Terrat_ep_tasks.get storage);
            (* Work manifests *)
            ( `POST,
              Rt.github_work_manifest_plan () --> Github_work_manifest.Plans.post config storage );
            ( `GET,
              Rt.github_get_work_manifest_plan () --> Github_work_manifest.Plans.get config storage
            );
            ( `PUT,
              Rt.github_work_manifest_results () --> Github_work_manifest.Results.put config storage
            );
            ( `POST,
              Rt.github_work_manifest_initiate ()
              --> Github_work_manifest.Initiate.post config storage );
            ( `POST,
              Rt.github_work_manifest_access_token ()
              --> Github_work_manifest.Access_token.post config storage );
            (* Github *)
            (`POST, Rt.github_events () --> Github_events.post config storage);
            (`GET, Rt.github_callback () --> Terrat_ep_github_callback.get config storage);
            (`GET, Rt.github_client_id () --> Terrat_ep_github_client_id.get config storage);
            (* User *)
            (`GET, Rt.whoami () --> Terrat_ep_whoami.get config storage);
            (`GET, Rt.user_installations_rt () --> Terrat_ep_user.Installations.get config storage);
            (* Installations *)
            ( `GET,
              Rt.installation_dirspaces_rt ()
              --> Terrat_ep_installations.Dirspaces.get config storage );
            ( `GET,
              Rt.installation_work_manifests_rt ()
              --> Terrat_ep_installations.Work_manifests.get config storage );
            ( `GET,
              Rt.installation_work_manifest_outputs_rt ()
              --> Terrat_ep_installations.Work_manifests.Outputs.get config storage );
            ( `GET,
              Rt.installation_pull_requests_manifests_rt ()
              --> Terrat_ep_installations.Pull_requests.get config storage );
            (`GET, Rt.installation_repos_rt () --> Terrat_ep_installations.Repos.get config storage);
            ( `POST,
              Rt.installation_repos_refresh_rt ()
              --> Terrat_ep_installations.Repos.Refresh.post config storage );
            (* Infracost *)
            (`POST, Rt.infracost () --> Terrat_ep_infracost.post config storage);
            (* Server *)
            (`GET, Rt.server_config () --> Terrat_ep_server.Config.get config);
            (* API 404s.  This is needed because for any and only UI endpoint we
               want to return the HTML *)
            (`GET, Rt.api_404 () --> fun _ ctx -> response_404 ctx);
            (`PUT, Rt.api_404 () --> fun _ ctx -> response_404 ctx);
            (`POST, Rt.api_404 () --> fun _ ctx -> response_404 ctx);
            (`DELETE, Rt.api_404 () --> fun _ ctx -> response_404 ctx);
          ])

  let start_telemetry config =
    match Terrat_config.telemetry config with
    | Terrat_config.Telemetry.Disabled ->
        Logs.info (fun m -> m "Telemetry disabled");
        Abbs_future_combinators.unit
    | Terrat_config.Telemetry.Anonymous uri as tc ->
        let open Abb.Future.Infix_monad in
        Logs.info (fun m -> m "Telemetry enabled with endpoint %a" Uri.pp uri);
        Terrat_telemetry.send
          tc
          (Terrat_telemetry.Event.Start { github_app_id = Terrat_config.github_app_id config })
        >>= fun () ->
        Abbs_future_combinators.ignore (Abb.Future.fork (Terrat_telemetry.start_ping_loop config))

  let run config storage =
    let open Abb.Future.Infix_monad in
    let one_min = Duration.of_min 1 in
    let five_min = Duration.of_min 5 in
    let cfg =
      Brtl_cfg.create
        ~read_header_timeout:one_min
        ~handler_timeout:five_min
        (Terrat_config.port config)
    in
    let mw_log =
      Brtl_mw_log.(
        create Config.{ remote_ip_header = Some "X-Forwarded-For"; extra_key = (fun _ -> None) })
    in
    Logs.info (fun m -> m "Creating storage connection");
    let mw_session = Terrat_session.create storage in
    let mw = Brtl_mw.create [ mw_log; mw_session ] in
    Logs.info (fun m -> m "Starting server");
    start_telemetry config
    >>= fun () ->
    Abb.Future.fork (Github_evaluator.Service.flow_state_cleanup config storage)
    >>= fun _ ->
    Abb.Future.fork (Github_evaluator.Service.plan_cleanup config storage)
    >>= fun _ ->
    Abb.Future.fork (Github_evaluator.Service.drift config storage)
    >>= fun _ ->
    Abb.Future.fork (Github_evaluator.Service.repo_config_cleanup config storage)
    >>= fun _ ->
    Abb.Future.fork
      (match Terrat_config.nginx_status_uri config with
      | Some uri ->
          Logs.info (fun m -> m "Starting nginx metrics: %s" (Uri.to_string uri));
          Terrat_nginx_metrics.start uri
      | None -> Abb.Future.return ())
    >>= fun _ ->
    Brtl.run cfg mw (rtng config storage)
    >>| function
    | Ok () -> ()
    | Error (`Exn exn) ->
        Logs.err (fun m -> m "%s" (Printexc.to_string exn));
        ()
    | Error `E_address_not_available ->
        Logs.err (fun m -> m "Failed to run server because address not available");
        ()
    | Error `E_address_family_not_supported ->
        Logs.err (fun m -> m "Failed to run server because address family not supported");
        ()
    | Error `E_address_in_use ->
        Logs.err (fun m -> m "Failed to run server because address already in use");
        ()
end
