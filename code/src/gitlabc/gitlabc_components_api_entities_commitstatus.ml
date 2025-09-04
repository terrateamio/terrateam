type t = {
  author : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  created_at : string option; [@default None]
  description : string option; [@default None]
  finished_at : string option; [@default None]
  id : int;
  name : string;
  pipeline_id : int option; [@default None]
  ref_ : string option; [@default None] [@key "ref"]
  sha : string option; [@default None]
  started_at : string option; [@default None]
  status : string;
  target_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
