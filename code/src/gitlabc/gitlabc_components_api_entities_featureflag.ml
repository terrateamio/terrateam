type t = {
  active : bool option; [@default None]
  created_at : string option; [@default None]
  description : string option; [@default None]
  name : string option; [@default None]
  scopes : string option; [@default None]
  strategies : Gitlabc_components_api_entities_featureflag_strategy.t option; [@default None]
  updated_at : string option; [@default None]
  version : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
