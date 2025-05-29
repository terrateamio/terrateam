module Primary = struct
  type t = {
    commit : Gitlabc_components_api_entities_commit.t option; [@default None]
    created_at : string option; [@default None]
    message : string option; [@default None]
    name : string option; [@default None]
    protected : bool option; [@default None]
    release : Gitlabc_components_api_entities_tagrelease.t option; [@default None]
    target : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
