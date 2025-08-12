module Extended_trailers = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

module Parent_ids = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Trailers = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

type t = {
  author_email : string option; [@default None]
  author_name : string option; [@default None]
  authored_date : string option; [@default None]
  committed_date : string option; [@default None]
  committer_email : string option; [@default None]
  committer_name : string option; [@default None]
  created_at : string option; [@default None]
  extended_trailers : Extended_trailers.t option; [@default None]
  id : string option; [@default None]
  last_pipeline : Gitlabc_components_api_entities_ci_pipelinebasic.t option; [@default None]
  message : string option; [@default None]
  parent_ids : Parent_ids.t option; [@default None]
  project_id : int option; [@default None]
  short_id : string option; [@default None]
  stats : Gitlabc_components_api_entities_commitstats.t option; [@default None]
  status : string option; [@default None]
  title : string option; [@default None]
  trailers : Trailers.t option; [@default None]
  web_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
