let response_404 ctx =
  Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)

let rtng config storage =
  Brtl_rtng.create
    ~default:(Brtl_static.run Terrat_files_assets.read "index.html")
    Brtl_rtng.Route.[]

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
  Logs.info (fun m -> m "Starting server");
  Brtl.run cfg mw (rtng config storage)
  >>| function
  | Ok () -> ()
  | Error (`Exn exn) ->
      Logs.err (fun m -> m "%s" (Printexc.to_string exn));
      ()
  | Error _ ->
      Logs.err (fun m -> m "Failed to run server for some reason");
      ()
