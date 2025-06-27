module Primary = struct
  type t = {
    action : string option; [@default None]
    created_at : string option; [@default None]
    id : int option; [@default None]
    milestone : Gitlabc_components_api_entities_milestone.t option; [@default None]
    resource_id : int option; [@default None]
    resource_type : string option; [@default None]
    state : string option; [@default None]
    user : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
