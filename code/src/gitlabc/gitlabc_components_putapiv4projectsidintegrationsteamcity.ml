type t = {
  build_type : string;
  enable_ssl_verification : bool option; [@default None]
  merge_requests_events : bool option; [@default None]
  password : string;
  push_events : bool option; [@default None]
  teamcity_url : string;
  use_inherited_settings : bool option; [@default None]
  username : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
