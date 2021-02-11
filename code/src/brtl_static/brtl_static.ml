let run lookup path ctx =
  match lookup path with
    | Some v -> (
        let etag = "\"" ^ Digest.(to_hex (string v)) ^ "\"" in
        let mime_type = Magic_mime.lookup path in
        match Cohttp.Header.get (Cohttp.Request.headers (Brtl_ctx.request ctx)) "if-none-match" with
          | Some tag when CCString.equal etag tag ->
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_modified "") ctx)
          | Some _ | None ->
              let headers =
                Cohttp.Header.of_list
                  [
                    ("content-type", mime_type);
                    ("content-length", CCInt.to_string (CCString.length v));
                    ("etag", etag);
                  ]
              in
              Abb.Future.return
                (Brtl_ctx.set_response (Brtl_rspnc.create ~headers ~status:`OK v) ctx) )
    | None   ->
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Not_found "") ctx)
