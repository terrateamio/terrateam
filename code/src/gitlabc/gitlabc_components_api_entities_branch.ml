module Primary = struct
  type t = {
    can_push : bool option; [@default None]
    commit : Gitlabc_components_api_entities_commit.t option; [@default None]
    default : bool option; [@default None]
    developers_can_merge : bool option; [@default None]
    developers_can_push : bool option; [@default None]
    merged : bool option; [@default None]
    name : string option; [@default None]
    protected : bool option; [@default None]
    web_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
