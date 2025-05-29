module Primary = struct
  type t = {
    awardable_id : int option; [@default None]
    awardable_type : string option; [@default None]
    created_at : string option; [@default None]
    id : int option; [@default None]
    name : string option; [@default None]
    updated_at : string option; [@default None]
    url : string option; [@default None]
    user : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
