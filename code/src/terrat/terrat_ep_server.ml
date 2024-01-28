module Config = struct
  let get config ctx =
    let body =
      Terrat_api_components.Server_config.(
        {
          github_app_client_id = Terrat_config.github_app_client_id config;
          github_app_url = Uri.to_string (Terrat_config.github_app_url config);
          github_web_base_url = Uri.to_string (Terrat_config.github_web_base_url config);
        }
        |> to_yojson
        |> Yojson.Safe.to_string)
    in
    Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)
end
