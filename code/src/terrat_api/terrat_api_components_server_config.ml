type t = {
  github : Terrat_api_components_server_config_github.t option; [@default None]
  gitlab : Terrat_api_components_server_config_gitlab.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
