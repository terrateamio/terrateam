let get config storage ctx =
  let body =
    Terrat_api_api_v1.Client_id.Responses.OK.(
      { client_id = Terrat_config.github_app_client_id config }
      |> to_yojson
      |> Yojson.Safe.to_string)
  in
  Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)
