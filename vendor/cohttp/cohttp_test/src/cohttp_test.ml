open Cohttp

module type S = sig
  type 'a io
  type ic
  type oc
  type body

  type response_action =
    [ `Expert of Cohttp.Response.t * (ic -> oc -> unit io)
    | `Response of Cohttp.Response.t * body ]

  type spec = Request.t -> body -> response_action io
  type async_test = unit -> unit io

  val response : Response.t * body -> response_action
  val expert : ?rsp:Cohttp.Response.t -> (ic -> oc -> unit io) -> spec
  val const : (Response.t * body) io -> spec
  val response_sequence : spec list -> spec
  val temp_server : ?port:int -> spec -> (Uri.t -> 'a io) -> 'a io

  val test_server_s :
    ?port:int ->
    ?name:string ->
    spec ->
    (Uri.t -> (string * async_test) list) ->
    OUnit.test io

  val run_async_tests : OUnit.test io -> OUnit.test_results io
end

let port = ref 9193

let next_port () =
  let current_port = !port in
  incr port;
  current_port

let response_sequence fail responses =
  let xs = ref responses in
  fun req body ->
    match !xs with
    | x :: xs' ->
        xs := xs';
        x req body
    | [] -> fail "response_sequence: Server exhausted responses"
