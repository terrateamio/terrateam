module Config = struct
  let get config ctx =
    let body =
      Terrat_api_components.Server_config.(
        {
          github =
            CCOption.map
              (fun github ->
                {
                  Terrat_api_components.Server_config_github.api_base_url =
                    Uri.to_string (Terrat_config.Github.api_base_url github);
                  app_client_id = Terrat_config.Github.app_client_id github;
                  app_url = Uri.to_string (Terrat_config.Github.app_url github);
                  web_base_url = Uri.to_string (Terrat_config.Github.web_base_url github);
                })
              (Terrat_config.github config);
        }
        |> to_yojson
        |> Yojson.Safe.to_string)
    in
    Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx)
end
