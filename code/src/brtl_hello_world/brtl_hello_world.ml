module Mw_log = Brtl_mw_log

let default_route ctx =
  Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)

let name name ctx =
  let body =
    CCResult.get_exn
      (Brtl_tmpl.render_string
         "<html><title>Hello</title><body>Welcome, @name@</body></html>\n"
         Brtl_tmpl.Kv.(Map.singleton "name" (string name)))
  in
  Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)

let age age ctx =
  let body =
    CCResult.get_exn
      (Brtl_tmpl.render_string
         "<html><title>Hello</title><body>You are @age@ years old.</body></html>\n"
         Brtl_tmpl.Kv.(Map.singleton "age" (int age)))
  in
  Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)

let slow ctx =
  let open Abb.Future.Infix_monad in
  Abb.Sys.sleep 10.0 >>| fun () -> Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx

let name_route () = Brtl_rtng.Route.(rel / "name" /% Path.string)
let age_route () = Brtl_rtng.Route.(rel / "age" /% Path.int)
let slow_route () = Brtl_rtng.Route.(rel / "slow")

let rtng =
  Brtl_rtng.create
    ~default:default_route
    Brtl_rtng.Route.
      [
        (`GET, name_route () --> name); (`GET, age_route () --> age); (`GET, slow_route () --> slow);
      ]

let () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level ~all:true (Some Logs.Debug);
  let run () =
    let open Abb.Future.Infix_monad in
    let cfg = Brtl_cfg.create ~handler_timeout:(Duration.of_sec 5) 8888 in
    let mw =
      Brtl_mw.create
        [ Mw_log.(create { Config.remote_ip_header = None; extra_key = CCFun.const None }) ]
    in
    Brtl.run cfg mw rtng >>| fun _ -> ()
  in
  match Abb.Scheduler.run_with_state run with
  | `Det () -> ()
  | _ -> assert false
