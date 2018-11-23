module Make(Abb: Abb_intf.S with type Native.t = Unix.file_descr) = struct
  module Brtl = Brtl.Make(Abb)

  let pre_handler = Brtl.Mw.pre_handler_noop

  let post_handler ctx =
    let rspnc = Brtl.Ctx.response ctx in
    let request = Brtl.Ctx.request ctx in
    let uri = Brtl.Ctx.Request.uri request in
    let status = Cohttp.Code.string_of_status (Brtl.Rspnc.status rspnc) in
    Logs.info (fun m -> m "%s %s" (Uri.to_string uri) status);
    Abb.Future.return ctx

  let early_exit_handler = Brtl.Mw.early_exit_handler_noop

  let create () =
    Brtl.Mw.Mw.create pre_handler post_handler early_exit_handler
end
