let src = Logs.Src.create "brtl_mw_log"

module Logs = (val Logs.src_log src : Logs.LOG)

module Config = struct
  type t = {
    remote_ip_header : string option;
    extra_key : (string, Brtl_rspnc.t) Brtl_ctx.t -> string option;
  }
end

let req_start_time = Hmap.Key.create ()

let pre_handler ctx =
  let open Abb.Future.Infix_monad in
  Abb.Sys.monotonic ()
  >>= fun start_time ->
  let ctx = Brtl_ctx.md_add req_start_time start_time ctx in
  Abb.Future.return (Brtl_mw.Pre_handler.Cont ctx)

let post_handler config ctx =
  let open Abb.Future.Infix_monad in
  let rspnc = Brtl_ctx.response ctx in
  let request = Brtl_ctx.request ctx in
  let uri = Brtl_ctx.Request.uri request in
  let status = Cohttp.Code.string_of_status (Brtl_rspnc.status rspnc) in
  let meth = Cohttp.Code.string_of_method (Brtl_ctx.Request.meth request) in
  let token = Brtl_ctx.token ctx in
  let headers = Brtl_ctx.Request.headers request in
  let remote_addr =
    CCOption.get_or
      ~default:(Brtl_ctx.remote_addr ctx)
      (CCOption.flat_map (Cohttp.Header.get headers) config.Config.remote_ip_header)
  in
  let extra_key =
    match config.Config.extra_key ctx with
    | Some s -> s
    | None -> ""
  in
  Abb.Sys.monotonic ()
  >>= fun end_time ->
  let duration =
    match Brtl_ctx.md_find req_start_time ctx with
    | Some start_time -> end_time -. start_time
    | None -> 0.0
  in
  Logs.info (fun m ->
      m
        "%s : %s : %s : %s : %f : %s : %s"
        extra_key
        remote_addr
        token
        meth
        duration
        (Uri.to_string uri)
        status);
  Abb.Future.return ctx

let early_exit_handler = Brtl_mw.early_exit_handler_noop
let create config = Brtl_mw.Mw.create pre_handler (post_handler config) early_exit_handler
