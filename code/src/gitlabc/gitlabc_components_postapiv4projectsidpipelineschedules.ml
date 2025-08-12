type t = {
  active : bool; [@default true]
  cron : string;
  cron_timezone : string; [@default "UTC"]
  description : string;
  ref_ : string; [@key "ref"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
