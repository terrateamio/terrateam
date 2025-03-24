type t = { github : Terrat_api_components_server_config_github.t option [@default None] }
[@@deriving yojson { strict = true; meta = true }, show, eq]
