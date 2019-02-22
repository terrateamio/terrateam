module Http = Cohttp_abb.Make(Abb)

type err = [ Cohttp_abb.request_err | `Bad_response ]

let tls_config =
  let cfg = Otls.Tls_config.create () in
  Otls.Tls_config.insecure_noverifycert cfg;
  cfg

let fetch uri =
  let open Abbs_future_combinators.Infix_result_monad in
  Http.Client.call ~tls_config `GET uri
  >>= function
  | (resp, body) when resp.Http.Response.status = `OK ->
    Abb.Future.return (Ok (Jwk.of_string body))
  | _ ->
    Abb.Future.return (Error `Bad_response)
