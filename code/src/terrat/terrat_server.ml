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

  let github () = Brtl_rtng.Route.(api () / "github" / "v1")
  let github_events () = Brtl_rtng.Route.(github () / "events")
  let github_work_manifest_plan () = work_manifest_plan github
  let github_work_manifest_initiate () = work_manifest_initiate github
  let github_work_manifest_results () = work_manifest_results github

  let github_get_work_manifest_plan () =
    Brtl_rtng.Route.(
      work_manifest github / "plans" /? Query.string "path" /? Query.string "workspace")

  let github_callback () =
    Brtl_rtng.Route.(
      github ()
      / "callback"
      /? Query.string "code"
      /? Query.(option (ud "installation_id" (CCOpt.wrap Int64.of_string))))

  let health_check () = Brtl_rtng.Route.(rel / "health")
end

let response_404 ctx =
  Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)

let rtng config storage =
  Brtl_rtng.create
    ~default:(Brtl_static.run Terrat_files_assets.read "index.html")
    Brtl_rtng.Route.
      [
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
        (* Github *)
        (`POST, Rt.github_events () --> Terrat_ep_github_events.post config storage);
        (`GET, Rt.github_callback () --> Terrat_ep_github_callback.get config storage);
        (`GET, Rt.health_check () --> Terrat_ep_health_check.get);
        (* API 404s.  This is needed because for any and only UI endpoint we
           want to return the HTML *)
        (`GET, Rt.api_404 () --> fun _ ctx -> response_404 ctx);
        (`PUT, Rt.api_404 () --> fun _ ctx -> response_404 ctx);
        (`POST, Rt.api_404 () --> fun _ ctx -> response_404 ctx);
        (`DELETE, Rt.api_404 () --> fun _ ctx -> response_404 ctx);
      ]

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
  Abb.Future.fork (Terrat_github_runner.run "STARTUP" config storage)
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
