type t = {
  enable_ssl_verification : bool option; [@default None]
  mock_service_url : string;
  push_events : bool option; [@default None]
  use_inherited_settings : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
