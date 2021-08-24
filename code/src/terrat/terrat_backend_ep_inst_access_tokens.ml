let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

let fetch_installation_access_token schema config storage installation_id =
  let open Abb.Future.Infix_monad in
  Abb.Sys.time ()
  >>= fun time ->
  let payload =
    let module P = Jwt.Payload in
    let module C = Jwt.Claim in
    P.empty
    |> P.add_claim C.iss (`String (Terrat_config.github_app_id config))
    |> P.add_claim C.iat (`Int (Float.to_int time - 60))
    |> P.add_claim C.exp (`Int (Float.to_int time + 60))
  in
  let signer = Jwt.Signer.(RS256 (Priv_key.of_priv_key (Terrat_config.github_app_pem config))) in
  let header = Jwt.Header.create (Jwt.Signer.to_string signer) in
  let jwt = Jwt.of_header_and_payload signer header payload in
  let token = Jwt.token jwt in
  let open Abbs_future_combinators.Infix_result_monad in
  Githubc_v3.create ~user_agent:"Terrateam" schema (`Bearer token)
  >>= fun github_client ->
  Githubc_v3.call github_client (Githubc_v3.installation_access_token installation_id github_client)
  >>= fun installation_access_token ->
  Abb.Future.return (Ok (Githubc_v3.Response.value installation_access_token))

let post schema config storage installation_id ctx =
  let open Abb.Future.Infix_monad in
  let request = Brtl_ctx.request ctx in
  let headers = Brtl_ctx.Request.headers request in
  Terrat_verify_jwt.verify storage headers
  >>= function
  | Ok (_, iat, exp, iss) -> (
      fetch_installation_access_token schema config storage installation_id
      >>= function
      | Ok installation_access_token ->
          let body =
            installation_access_token
            |> Githubc_v3.Type.Installation_access_token.to_yojson
            |> Yojson.Safe.to_string
          in
          Abb.Future.return
            (Brtl_ctx.set_response
               (Brtl_rspnc.create ~headers:response_headers ~status:`Created body)
               ctx)
      | Error (#Githubc_v3.call_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_MOCK : INSTALLATION_ACCESS_TOKEN : FAILED : %s"
                (Githubc_v3.show_call_err err));
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
  | Error (#Terrat_verify_jwt.err as err) ->
      Logs.err (fun m ->
          m "GITHUB_MOCK : INSTALLATION_ACCESS_TOKEN : FAILED : %s" (Terrat_verify_jwt.show_err err));
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
