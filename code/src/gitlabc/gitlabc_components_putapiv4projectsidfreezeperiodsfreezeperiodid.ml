type t = {
  cron_timezone : string option; [@default None]
  freeze_end : string option; [@default None]
  freeze_start : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
