module Http = Cohttp_abb.Make (Abb)
module Response = Cohttp.Response

module Encoding = struct
  type t = Cohttp.Transfer.encoding

  let chunked = Cohttp.Transfer.Chunked

  let fixed = Cohttp.Transfer.Fixed Int64.max_int
end

type t = {
  response : Response.t;
  body : Http.Response_io.writer -> unit Abb.Future.t;
}

let create_stream
    ?version
    ?(headers = Cohttp.Header.init ())
    ?(encoding = Encoding.chunked)
    ~status
    body =
  let headers = Cohttp.Header.add_unless_exists headers "content-type" "text/html" in
  let headers = Cohttp.Header.add_unless_exists headers "connection" "keep-alive" in
  { response = Response.make ?version ~headers ~status (); body }

let create ?version ?(headers = Cohttp.Header.init ()) ?(encoding = Encoding.chunked) ~status body =
  create_stream ?version ~headers ~encoding ~status (fun writer ->
      Http.Response_io.write_body writer body)

let version t = Response.version t.response

let status t = Response.status t.response

let body t = t.body

let headers t = Response.headers t.response

let add_header name value t =
  let hdrs = Cohttp.Header.add t.response.Response.headers name value in
  let response = { t.response with Response.headers = hdrs } in
  { t with response }

let response t = t.response
