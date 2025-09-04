type t = {
  config_project : Gitlabc_components_api_entities_projectidentity.t option; [@default None]
  created_at : string option; [@default None]
  created_by_user_id : string option; [@default None]
  id : string option; [@default None]
  is_receptive : string option; [@default None]
  name : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
