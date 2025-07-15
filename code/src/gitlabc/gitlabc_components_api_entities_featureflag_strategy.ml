type t = {
  id : int option; [@default None]
  name : string option; [@default None]
  parameters : string option; [@default None]
  scopes : Gitlabc_components_api_entities_featureflag_scope.t option; [@default None]
  user_list : Gitlabc_components_api_entities_featureflag_basicuserlist.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
