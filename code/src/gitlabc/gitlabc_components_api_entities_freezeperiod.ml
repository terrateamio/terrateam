type t = {
  created_at : string option; [@default None]
  cron_timezone : string option; [@default None]
  freeze_end : string option; [@default None]
  freeze_start : string option; [@default None]
  id : int option; [@default None]
  updated_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
