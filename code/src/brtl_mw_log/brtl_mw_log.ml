let pre_handler = Brtl_mw.pre_handler_noop

let post_handler ctx =
  let rspnc = Brtl_ctx.response ctx in
  let request = Brtl_ctx.request ctx in
  let uri = Brtl_ctx.Request.uri request in
  let status = Cohttp.Code.string_of_status (Brtl_rspnc.status rspnc) in
  Logs.info (fun m -> m "%s %s" (Uri.to_string uri) status);
  Abb.Future.return ctx

let early_exit_handler = Brtl_mw.early_exit_handler_noop

let create () =
  Brtl_mw.Mw.create pre_handler post_handler early_exit_handler
