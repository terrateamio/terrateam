module Fut_comb = Abbs_future_combinators

module Http = Cohttp_abb.Make(Abb)

module Cfg = Brtl_cfg
module Ctx = Brtl_ctx
module Mw = Brtl_mw
module Rspnc = Brtl_rspnc
module Rtng = Brtl_rtng
module Tmpl = Brtl_tmpl

let rec read_body_chunks r b =
  let open Abb.Future.Infix_monad in
  Http.Request_io.read_body_chunk r
  >>= function
  | Cohttp.Transfer.Chunk s ->
    Buffer.add_string b s;
    read_body_chunks r b
  | Cohttp.Transfer.Final_chunk s ->
    Buffer.add_string b s;
    Fut_comb.unit
  | Cohttp.Transfer.Done ->
    Fut_comb.unit

(* TODO: Limit size of body *)
let read_body req ic =
  let b = Buffer.create 1024 in
  match Http.Request_io.has_body req with
    | `Yes | `Unknown ->
      let open Abb.Future.Infix_monad in
      read_body_chunks (Http.Request_io.make_body_reader req ic) b
      >>= fun () ->
      Abb.Future.return (Buffer.contents b)
    | `No ->
      Abb.Future.return ""

let write_response oc rspnc =
  Http.Response_io.write
    (fun writer -> Http.Response_io.write_body writer (Rspnc.body rspnc))
    (Rspnc.response rspnc)
    oc

let run_handler hndlr ctx =
  let open Abb.Future.Infix_monad in
  Abb.Future.await
    (Fut_comb.on_failure
       (fun () -> hndlr ctx)
       ~failure:(fun () -> Fut_comb.unit))
  >>= function
  | `Det v ->
    Abb.Future.return v
  | `Aborted ->
    Abb.Future.return (Ctx.set_response (Rspnc.create ~status:`Internal_server_error "") ctx)
  | `Exn (exn, bt_opt) ->
    Logs.err (fun m -> m "Exception: %s" (Printexc.to_string exn));
    CCOpt.iter
      (fun bt -> Logs.err (fun m -> m "Backtrace: %s" (Printexc.raw_backtrace_to_string bt)))
      bt_opt;
    Abb.Future.return (Ctx.set_response (Rspnc.create ~status:`Internal_server_error "") ctx)

let handler mw rtng req ic oc =
  let open Abb.Future.Infix_monad in
  let ctx = Ctx.create req in
  Mw.exec_pre_handler ctx mw
  >>= function
  | Mw.Pre_handler.Cont ctx ->
    let hndlr = Rtng.route ctx rtng in
    read_body req ic
    >>= fun body ->
    let ctx = Ctx.set_body body ctx in
    run_handler hndlr ctx
    >>= fun ctx ->
    Mw.exec_post_handler ctx mw
    >>= fun ctx ->
    write_response oc (Ctx.response ctx)
    >>= fun () ->
    Abb.Future.return `Ok
  | Mw.Pre_handler.Stop ctx ->
    Mw.exec_early_exit_handler ctx mw
    >>= fun ctx ->
    write_response oc (Ctx.response ctx)
    >>= fun () ->
    Abb.Future.return `Ok

let on_handler_exn req (exn, bt_opt) =
    Logs.err (fun m -> m "Exception: %s" (Printexc.to_string exn));
    CCOpt.iter
      (fun bt -> Logs.err (fun m -> m "Backtrace: %s" (Printexc.raw_backtrace_to_string bt)))
      bt_opt;
    Abb.Future.return `Ok

let run cfg mw rtng =
  let config =
    Http.Server.(Config.of_view
                   { Config.View.scheme = Scheme.Http
                   ; on_handler_exn = on_handler_exn
                   ; port = Cfg.port cfg
                   ; handler = handler mw rtng
                   ; read_header_timeout = Cfg.read_header_timeout cfg
                   ; handler_timeout = Cfg.handler_timeout cfg
                   })
  in
  let open Abb.Future.Infix_monad in
  Http.Server.run (CCResult.get_exn config)
  >>| fun _ ->
  ()

