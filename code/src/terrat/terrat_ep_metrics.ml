let get ctx =
  let data = Prmths.CollectorRegistry.(collect default) in
  let body = Fmt.to_to_string Prmths.TextFormat_0_0_4.output data in
  Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)
