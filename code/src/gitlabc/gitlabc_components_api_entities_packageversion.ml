type t = {
  created_at : string option; [@default None]
  id : string option; [@default None]
  pipeline : Gitlabc_components_api_entities_package_pipeline.t option; [@default None]
  tags : string option; [@default None]
  version : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
