type t = {
  pipeline_events : bool option; [@default None]
  repository_url : string;
  static_context : bool option; [@default None]
  token : string;
  use_inherited_settings : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
