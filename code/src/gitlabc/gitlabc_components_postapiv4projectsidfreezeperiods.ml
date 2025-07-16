type t = {
  cron_timezone : string option; [@default None]
  freeze_end : string;
  freeze_start : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
