type t = {
  created_at : string option; [@default None]
  id : int option; [@default None]
  iid : int option; [@default None]
  project_id : int option; [@default None]
  ref_ : string option; [@default None] [@key "ref"]
  sha : string option; [@default None]
  source : string option; [@default None]
  status : string option; [@default None]
  updated_at : string option; [@default None]
  web_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
