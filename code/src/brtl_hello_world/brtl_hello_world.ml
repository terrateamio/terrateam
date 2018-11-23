module Abb = Abb_scheduler_select

module Brtl = Brtl.Make(Abb)

module Mw_log = Brtl_mw_log.Make(Abb)

let default_route ctx =
  Abb.Future.return
    Brtl.(Ctx.set_response (Rspnc.create ~status:`Not_found "") ctx)

let name name ctx =
  let body =
    CCResult.get_exn
      (Brtl.Tmpl.render_string
         "<html><title>Hello</title><body>Welcome, @name@</body></html>"
         Brtl.Tmpl.Kv.(Map.singleton "name" (string name)))
  in
  Abb.Future.return
    Brtl.(Ctx.set_response
            (Rspnc.create ~status:`OK body)
            ctx)

let age age ctx =
  let body =
    CCResult.get_exn
      (Brtl.Tmpl.render_string
         "<html><title>Hello</title><body>You are @age@ years old.</body></html>"
         Brtl.Tmpl.Kv.(Map.singleton "age" (int age)))
  in
  Abb.Future.return
    Brtl.(Ctx.set_response
            (Rspnc.create ~status:`OK body)
            ctx)

let name_route () =
  Brtl.Rtng.Route.(rel / "name" /% Path.string)

let age_route () =
  Brtl.Rtng.Route.(rel / "age" /% Path.int)

let rtng =
  Brtl.Rtng.create
    ~default:default_route
    Brtl.Rtng.Route.([ (`GET, name_route () --> name)
                     ; (`GET, age_route () --> age)
                     ])

let () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level ~all:true (Some Logs.Debug);
  let run () =
    let cfg = Brtl.Cfg.create ~port:8888 ~read_header_timeout:None ~handler_timeout:None in
    let mw = Brtl.Mw.create [Mw_log.create ()] in
    Brtl.run cfg mw rtng
  in
  match Abb.Scheduler.run (Abb.Scheduler.create ()) run with
    | `Det () -> ()
    | _ -> assert false
