type t = {
  active : bool option; [@default None]
  cron : string option; [@default None]
  cron_timezone : string option; [@default None]
  description : string option; [@default None]
  ref_ : string option; [@default None] [@key "ref"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
