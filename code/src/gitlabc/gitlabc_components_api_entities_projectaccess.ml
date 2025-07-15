type t = {
  access_level : string option; [@default None]
  notification_level : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
