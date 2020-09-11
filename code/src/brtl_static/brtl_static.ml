let run lookup path ctx =
  match lookup path with
    | Some v ->
        let mime_type = Magic_mime.lookup path in
        let headers = Cohttp.Header.of_list [ ("content-type", mime_type) ] in
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~headers ~status:`OK v) ctx)
    | None   ->
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
