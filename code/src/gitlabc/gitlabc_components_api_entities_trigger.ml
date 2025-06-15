module Primary = struct
  type t = {
    created_at : string option; [@default None]
    description : string option; [@default None]
    expires_at : string option; [@default None]
    id : int option; [@default None]
    last_used : string option; [@default None]
    owner : Gitlabc_components_api_entities_userbasic.t option; [@default None]
    token : string option; [@default None]
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
