let health_rt () = Brtl_rtng.Route.(rel / "health")
let app_rt () = Brtl_rtng.Route.(rel / "api/v3/app")
let installations_rt () = Brtl_rtng.Route.(app_rt () / "installations")

let access_tokens_rt () =
  Brtl_rtng.Route.(installations_rt () /% Path.ud CCInt64.of_string / "access_tokens")

let api_v1_rt () = Brtl_rtng.Route.(rel / "api" / "v1")
let installation_rt () = Brtl_rtng.Route.(api_v1_rt () / "installation")
let secrets_rt () = Brtl_rtng.Route.(installation_rt () / "secrets")
let env_vars_rt () = Brtl_rtng.Route.(installation_rt () / "env-vars")
let config_rt () = Brtl_rtng.Route.(installation_rt () / "config")

let rtng config storage schema =
  Brtl_rtng.create
    ~default:(fun ctx ->
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx))
    Brtl_rtng.Route.
      [
        ( `POST,
          access_tokens_rt () --> Terrat_backend_ep_inst_access_tokens.post schema config storage );
        (`GET, installations_rt () --> Terrat_backend_ep_inst.get schema config storage);
        (`GET, health_rt () --> Terrat_ep_health.get);
        (`GET, secrets_rt () --> Terrat_backend_ep_secrets.get storage);
        (`GET, env_vars_rt () --> Terrat_backend_ep_env_vars.get storage);
        (`GET, config_rt () --> Terrat_backend_ep_config.get storage);
      ]

let run config storage =
  let open Abb.Future.Infix_monad in
  let one_min = Duration.of_min 1 in
  let five_min = Duration.of_min 5 in
  let cfg =
    Brtl_cfg.create
      ~read_header_timeout:one_min
      ~handler_timeout:five_min
      (Terrat_config.backend_port config)
  in
  let mw_log =
    Brtl_mw_log.(
      create Config.{ remote_ip_header = Some "X-Forwarded-For"; extra_key = (fun _ -> None) })
  in
  let mw = Brtl_mw.create [ mw_log ] in
  Logs.info (fun m -> m "Loading backend github schema");
  Githubc_v3.Schema.create ()
  >>= function
  | Ok schema -> (
      Logs.info (fun m -> m "Starting backend server");
      Brtl.run cfg mw (rtng config storage schema)
      >>| function
      | Ok () -> ()
      | Error (`Exn exn) ->
          Logs.err (fun m -> m "%s" (Printexc.to_string exn));
          ()
      | Error _ ->
          Logs.err (fun m -> m "Failed to run server for some reason");
          ())
  | Error _ ->
      Logs.err (fun m -> m "Failed to load github schema");
      Abb.Future.return ()
