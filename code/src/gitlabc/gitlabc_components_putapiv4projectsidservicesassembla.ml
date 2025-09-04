type t = {
  push_events : bool option; [@default None]
  subdomain : string option; [@default None]
  token : string;
  use_inherited_settings : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
