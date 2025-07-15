type t = {
  active : bool option; [@default None]
  created_at : string option; [@default None]
  cron : string option; [@default None]
  cron_timezone : string option; [@default None]
  description : string option; [@default None]
  id : int option; [@default None]
  next_run_at : string option; [@default None]
  owner : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  ref_ : string option; [@default None] [@key "ref"]
  updated_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
