module Primary = struct
  type t = {
    comment : string option; [@default None]
    created_at : string option; [@default None]
    status : string option; [@default None]
    user : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
