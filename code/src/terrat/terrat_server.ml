module Rt = struct
  let api () = Brtl_rtng.Route.(rel / "api")
  let api_404 () = Brtl_rtng.Route.(api () /% Path.any)
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
  let admin_rt () = Brtl_rtng.Route.(api () / "v1" / "admin")
  let admin_drift_list_rt () = Brtl_rtng.Route.(admin_rt () / "drifts")
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
    ~default:(Brtl_static.run Terrat_files_assets.read "index.html")
    (maybe_add_admin_routes config storage
    @ Brtl_rtng.Route.
        [
          (* Ops *)
          (`GET, Rt.health_check () --> Terrat_ep_health_check.get storage);
          (`GET, Rt.metrics () --> Terrat_ep_metrics.get);
          (* Work manifests *)
          ( `POST,
            Rt.github_work_manifest_plan ()
            --> Terrat_ep_github_work_manifest.Plans.post config storage );
          ( `GET,
            Rt.github_get_work_manifest_plan ()
            --> Terrat_ep_github_work_manifest.Plans.get config storage );
          ( `PUT,
            Rt.github_work_manifest_results ()
            --> Terrat_ep_github_work_manifest.Results.put config storage );
          ( `POST,
            Rt.github_work_manifest_initiate ()
            --> Terrat_ep_github_work_manifest.Initiate.post config storage );
          ( `POST,
            Rt.github_work_manifest_access_token ()
            --> Terrat_ep_github_work_manifest.Access_token.post config storage );
          (* Github *)
          (`POST, Rt.github_events () --> Terrat_ep_github_events.post config storage);
          (`GET, Rt.github_callback () --> Terrat_ep_github_callback.get config storage);
          (* Infracost *)
          (`POST, Rt.infracost () --> Terrat_ep_infracost.post config storage);
          (* API 404s.  This is needed because for any and only UI endpoint we
             want to return the HTML *)
          (`GET, Rt.api_404 () --> fun _ ctx -> response_404 ctx);
          (`PUT, Rt.api_404 () --> fun _ ctx -> response_404 ctx);
          (`POST, Rt.api_404 () --> fun _ ctx -> response_404 ctx);
          (`DELETE, Rt.api_404 () --> fun _ ctx -> response_404 ctx);
        ])

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
  Abb.Future.fork (Terrat_github_evaluator.Runner.run ~request_id:"STARTUP" config storage)
  >>= fun _ ->
  Abb.Future.fork (Terrat_github_evaluator.Drift.Service.run config storage)
  >>= fun _ ->
  Abb.Future.fork (Terrat_github_plan_cleanup.start storage)
  >>= fun _ ->
  Abb.Future.fork
    (match Terrat_config.nginx_status_uri config with
    | Some uri ->
        Logs.debug (fun m -> m "Starting nginx metrics: %s" (Uri.to_string uri));
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
