type t = {
  api_key : string;
  push_events : bool option; [@default None]
  restrict_to_branch : string option; [@default None]
  use_inherited_settings : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
