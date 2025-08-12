type t = {
  akismet_submitted : bool option; [@default None]
  ip_address : string option; [@default None]
  user_agent : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
