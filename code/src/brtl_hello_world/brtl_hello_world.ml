module Mw_log = Brtl_mw_log

let default_route ctx =
  Abb.Future.return
    (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)

let name name ctx =
  let body =
    CCResult.get_exn
      (Brtl_tmpl.render_string
         "<html><title>Hello</title><body>Welcome, @name@</body></html>"
         Brtl_tmpl.Kv.(Map.singleton "name" (string name)))
  in
  Abb.Future.return
    (Brtl_ctx.set_response
       (Brtl_rspnc.create ~status:`OK body)
       ctx)

let age age ctx =
  let body =
    CCResult.get_exn
      (Brtl_tmpl.render_string
         "<html><title>Hello</title><body>You are @age@ years old.</body></html>"
         Brtl_tmpl.Kv.(Map.singleton "age" (int age)))
  in
  Abb.Future.return
    (Brtl_ctx.set_response
       (Brtl_rspnc.create ~status:`OK body)
       ctx)

let name_route () =
  Brtl_rtng.Route.(rel / "name" /% Path.string)

let age_route () =
  Brtl_rtng.Route.(rel / "age" /% Path.int)

let rtng =
  Brtl_rtng.create
    ~default:default_route
    Brtl_rtng.Route.([ (`GET, name_route () --> name)
                     ; (`GET, age_route () --> age)
                     ])

let () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level ~all:true (Some Logs.Debug);
  let run () =
    let cfg = Brtl_cfg.create ~port:8888 ~read_header_timeout:None ~handler_timeout:None in
    let mw = Brtl_mw.create [Mw_log.(create {Config.remote_ip_header = None})] in
    Brtl.run cfg mw rtng
  in
  match Abb.Scheduler.run (Abb.Scheduler.create ()) run with
    | `Det () -> ()
    | _ -> assert false
