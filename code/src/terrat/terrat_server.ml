module Rt = struct
  let api () = Brtl_rtng.Route.(rel / "api")
  let api_404 () = Brtl_rtng.Route.(api () /% Path.any)
  let api_v1 () = Brtl_rtng.Route.(api () / "v1")
  let whoami () = Brtl_rtng.Route.(api_v1 () / "whoami")
  let logout () = Brtl_rtng.Route.(api_v1 () / "logout")
  let server_config () = Brtl_rtng.Route.(api_v1 () / "server" / "config")
  let health_check () = Brtl_rtng.Route.(rel / "health")
  let infracost () = Brtl_rtng.Route.(api () / "github" / "infracost" /% Path.any)
  let metrics () = Brtl_rtng.Route.(rel / "metrics")

  (* Admin interface *)
  let admin_rt () = Brtl_rtng.Route.(api_v1 () / "admin")
  let admin_drift_list_rt () = Brtl_rtng.Route.(admin_rt () / "drifts")

  (* Tasks API *)
  let tasks_api_rt () = Brtl_rtng.Route.(api_v1 () / "tasks")
  let task_rt () = Brtl_rtng.Route.(tasks_api_rt () /% Path.ud Uuidm.of_string)

  (* Tenv *)
  let tenv_rt () =
    Brtl_rtng.Route.(rel / "api" /% Path.string / "tenv" /% Path.ud Uuidm.of_string /% Path.any)
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

let rtng config storage services =
  let routes =
    CCList.flat_map
      (function
        | Terrat_vcs_service.Service ((module M), service) -> M.Service.routes service)
      services
  in
  Brtl_rtng.create
    ~default:(fun ctx ->
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx))
    (maybe_add_admin_routes config storage
    @ Brtl_rtng.Route.(
        [
          (* Ops *)
          (`GET, Rt.health_check () --> Terrat_ep_health_check.get storage);
          (`GET, Rt.metrics () --> Terrat_ep_metrics.get);
          (* Tasks *)
          (`GET, Rt.task_rt () --> Terrat_ep_tasks.get storage);
        ]
        @ routes
        @ [
            (* Tenv *)
            (`GET, Rt.tenv_rt () --> Terrat_ep_tenv.get config storage);
            (* User *)
            (`GET, Rt.whoami () --> Terrat_ep_whoami.get config storage services);
            (`POST, Rt.logout () --> Terrat_ep_logout.post storage);
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
          ]))

let start_telemetry config =
  match Terrat_config.telemetry config with
  | Terrat_config.Telemetry.Disabled ->
      Logs.info (fun m -> m "Telemetry disabled");
      Abbs_future_combinators.unit
  | Terrat_config.Telemetry.Anonymous uri as tc ->
      let open Abb.Future.Infix_monad in
      Logs.info (fun m -> m "Telemetry enabled with endpoint %a" Uri.pp uri);
      (match Terrat_config.github config with
      | Some github ->
          Terrat_telemetry.send
            tc
            (Terrat_telemetry.Event.Start
               { app_type = "github"; app_id = Terrat_config.Github.app_id github })
      | None -> Abb.Future.return ())
      >>= fun () ->
      Abbs_future_combinators.ignore (Abb.Future.fork (Terrat_telemetry.start_ping_loop config))

let run config storage services =
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
  Abb.Future.fork
    (match Terrat_config.nginx_status_uri config with
    | Some uri ->
        Logs.info (fun m -> m "Starting nginx metrics: %s" (Uri.to_string uri));
        Terrat_nginx_metrics.start uri
    | None -> Abb.Future.return ())
  >>= fun _ ->
  Brtl.run cfg mw (rtng config storage services)
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
