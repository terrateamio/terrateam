module Primary = struct
  type t = {
    create_access_levels : Gitlabc_components_api_entities_protectedrefaccess.t option;
        [@default None]
    name : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
