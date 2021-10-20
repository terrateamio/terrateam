let health_rt () = Brtl_rtng.Route.(rel / "health")

let assets_rt () = Brtl_rtng.Route.(rel / "assets" /% Path.string)

let index_rt () = Brtl_rtng.Route.(rel / "index.html")

let cookies_rt () = Brtl_rtng.Route.(rel / "cookies.html")

let privacy_rt () = Brtl_rtng.Route.(rel / "privacy.html")

let terms_rt () = Brtl_rtng.Route.(rel / "terms.html")

let root_rt () = Brtl_rtng.Route.(rel / "")

let github_rt () = Brtl_rtng.Route.(rel / "github")

let github_callback_rt () = Brtl_rtng.Route.(github_rt () / "callback" /? Query.string "code")

let github_events_rt () = Brtl_rtng.Route.(github_rt () / "events")

let api_v1_rt () = Brtl_rtng.Route.(rel / "api" / "v1")

let api_v1_404_rt () = Brtl_rtng.Route.(api_v1_rt () /% Path.any)

let logout_rt () = Brtl_rtng.Route.(api_v1_rt () / "logout")

let whoami_rt () = Brtl_rtng.Route.(api_v1_rt () / "whoami")

let user_rt () = Brtl_rtng.Route.(api_v1_rt () / "user")

let user_update_rt () =
  Brtl_rtng.Route.(user_rt () /* Body.decode ~json:Terrat_data.Request.User_prefs.of_yojson ())

let user_sessions_rt () = Brtl_rtng.Route.(user_rt () / "sessions")

let oauth_config_rt () = Brtl_rtng.Route.(api_v1_rt () / "oauth" / "config")

let installations_rt () = Brtl_rtng.Route.(api_v1_rt () / "installations")

let installation_rt () =
  Brtl_rtng.Route.(installations_rt () /% Path.ud (CCOpt.wrap Int64.of_string))

let secrets_rt () = Brtl_rtng.Route.(installation_rt () / "secrets")

let secrets_list_rt () =
  let pagination = function
    | [ direction; name ] -> Some (direction, name)
    | _                   -> None
  in
  Brtl_rtng.Route.(
    secrets_rt ()
    /? Query.option_default 30 (Query.int "limit")
    /? Query.option (Query.ud_array "page" pagination))

let secrets_detail_rt () = Brtl_rtng.Route.(secrets_rt () /% Path.string)

let secrets_create_rt () =
  Brtl_rtng.Route.(secrets_rt () /* Body.decode ~json:Terrat_data.Request.Secret.of_yojson ())

let env_vars_rt () = Brtl_rtng.Route.(installation_rt () / "env-vars")

let env_vars_list_rt () =
  let pagination = function
    | [ direction; name ] -> Some (direction, name)
    | _                   -> None
  in
  Brtl_rtng.Route.(
    env_vars_rt ()
    /? Query.option_default 30 (Query.int "limit")
    /? Query.option (Query.ud_array "page" pagination))

let env_var_detail_rt () = Brtl_rtng.Route.(env_vars_rt () /% Path.string)

let env_var_create_rt () =
  Brtl_rtng.Route.(env_vars_rt () /* Body.decode ~json:Terrat_data.Request.Env_var.of_yojson ())

let config_rt () = Brtl_rtng.Route.(installation_rt () / "config")

let config_set_rt () =
  Brtl_rtng.Route.(config_rt () /* Body.decode ~json:Terrat_data.Request.Config.of_yojson ())

let terraform_rt () = Brtl_rtng.Route.(api_v1_rt () / "terraform")

let terraform_versions_rt () = Brtl_rtng.Route.(terraform_rt () / "versions")

let feedback_rt () =
  Brtl_rtng.Route.(
    installation_rt ()
    / "feedback"
    /* Body.decode ~json:Terrat_data.Request.User_feedback.of_yojson ())

let response_404 ctx =
  Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)

let rtng config storage schema =
  Brtl_rtng.create
    ~default:(Brtl_static.run Terrat_files_assets.read "index.html")
    Brtl_rtng.Route.
      [
        (`GET, assets_rt () --> Brtl_static.run Terrat_files_assets.read);
        (`GET, index_rt () --> Brtl_static.run Terrat_files_assets.read "index.html");
        (`GET, cookies_rt () --> Brtl_static.run Terrat_files_assets.read "cookies.html");
        (`GET, privacy_rt () --> Brtl_static.run Terrat_files_assets.read "privacy.html");
        (`GET, terms_rt () --> Brtl_static.run Terrat_files_assets.read "terms.html");
        (`GET, root_rt () --> Brtl_static.run Terrat_files_assets.read "index.html");
        (`POST, github_events_rt () --> Terrat_ep_github_events.post config storage);
        (`GET, health_rt () --> Terrat_ep_health.get);
        (* Secrets *)
        (`GET, secrets_list_rt () --> Terrat_ep_secrets.get config storage schema);
        (`PUT, secrets_create_rt () --> Terrat_ep_secrets.put config storage schema);
        (`DELETE, secrets_detail_rt () --> Terrat_ep_secrets.delete config storage schema);
        (* Env vars *)
        (`GET, env_vars_list_rt () --> Terrat_ep_env_vars.get config storage schema);
        (`PUT, env_var_create_rt () --> Terrat_ep_env_vars.put config storage schema);
        (`DELETE, env_var_detail_rt () --> Terrat_ep_env_vars.delete config storage schema);
        (* Config *)
        (`GET, config_rt () --> Terrat_ep_config.get config storage schema);
        (`PUT, config_set_rt () --> Terrat_ep_config.put config storage schema);
        (* Terraform version *)
        (`GET, terraform_versions_rt () --> Terrat_ep_terraform_versions.get storage);
        (* Other *)
        (`GET, github_callback_rt () --> Terrat_ep_github_callback.get config storage schema);
        (`GET, oauth_config_rt () --> Terrat_ep_oauth_config.get config);
        (`GET, installations_rt () --> Terrat_ep_installations.get config storage schema);
        (`GET, whoami_rt () --> Terrat_ep_whoami.get config storage schema);
        (`GET, user_sessions_rt () --> Terrat_ep_sessions.get storage);
        (`DELETE, user_sessions_rt () --> Terrat_ep_sessions.delete storage);
        (`GET, user_rt () --> Terrat_ep_user.Prefs.get storage);
        (`PUT, user_update_rt () --> Terrat_ep_user.Prefs.put storage);
        (`POST, logout_rt () --> Terrat_ep_logout.post storage);
        (`POST, feedback_rt () --> Terrat_ep_feedback.post config storage schema);
        (* API 404s.  This is needed because for any and only UI endpoint we
           want to return the HTML *)
        (`GET, api_v1_404_rt () --> fun _ ctx -> response_404 ctx);
        (`PUT, api_v1_404_rt () --> fun _ ctx -> response_404 ctx);
        (`POST, api_v1_404_rt () --> fun _ ctx -> response_404 ctx);
        (`DELETE, api_v1_404_rt () --> fun _ ctx -> response_404 ctx);
      ]

let run config storage =
  let open Abb.Future.Infix_monad in
  let one_min = Duration.of_min 1 in
  let five_min = Duration.of_min 5 in
  let cfg =
    Brtl_cfg.create
      ~read_header_timeout:one_min
      ~handler_timeout:five_min
      (Terrat_config.frontend_port config)
  in
  let mw_log =
    Brtl_mw_log.(
      create Config.{ remote_ip_header = Some "X-Forwarded-For"; extra_key = (fun _ -> None) })
  in
  let mw_session = Terrat_session.create storage in
  let mw = Brtl_mw.create [ mw_log; mw_session ] in
  Logs.info (fun m -> m "Loading frontend github schema");
  Githubc_v3.Schema.create ()
  >>= function
  | Ok schema -> (
      Logs.info (fun m -> m "Starting server");
      Brtl.run cfg mw (rtng config storage schema)
      >>| function
      | Ok ()            -> ()
      | Error (`Exn exn) ->
          Logs.err (fun m -> m "%s" (Printexc.to_string exn));
          ()
      | Error _          ->
          Logs.err (fun m -> m "Failed to run server for some reason");
          ())
  | Error _   ->
      Logs.err (fun m -> m "Failed to load frontend github schema");
      Abb.Future.return ()
