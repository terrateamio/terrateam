module Make(Abb : Abb_intf.S) = struct
  module Response = Cohttp.Response

  type t = { response: Response.t
           ; body: string
           }

  let create ?version ?(headers = Cohttp.Header.init ()) ~status body =
    let headers = Cohttp.Header.add_unless_exists headers "content-type" "text/html" in
    { response = Response.make ?version ~headers ~status ()
    ; body = body
    }

  let version t = Response.version t.response
  let status t = Response.status t.response
  let body t = t.body

  let headers t = Response.headers t.response
  let add_header name value t =
    let hdrs =
      Cohttp.Header.add
        t.response.Response.headers
        name
        value
    in
    let response = { t.response with Response.headers = hdrs } in
    { t with response = response }

  let response t = t.response
end
