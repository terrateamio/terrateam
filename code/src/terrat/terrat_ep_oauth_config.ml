let resp_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

let get config ctx =
  let client_id = Terrat_config.github_app_client_id config in
  let url =
    Uri.make
      ~scheme:"https"
      ~host:"github.com"
      ~path:"/login/oauth/authorize"
      ~query:[ ("client_id", [ client_id ]) ]
      ()
  in
  let body =
    Terrat_data.Response.Oauth_config.(
      { url = Uri.to_string url } |> to_yojson |> Yojson.Safe.to_string)
  in
  Abb.Future.return
    (Brtl_ctx.set_response (Brtl_rspnc.create ~headers:resp_headers ~status:`OK body) ctx)
