type t = {
  colorize_messages : bool option; [@default None]
  default_irc_uri : string option; [@default None]
  push_events : bool option; [@default None]
  recipients : string;
  server_host : string option; [@default None]
  server_port : int option; [@default None]
  use_inherited_settings : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
