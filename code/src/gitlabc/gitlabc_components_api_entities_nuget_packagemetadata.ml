module Primary = struct
  type t = {
    id_ : string option; [@default None] [@key "@id"]
    catalogentry : Gitlabc_components_api_entities_nuget_packagemetadatacatalogentry.t option;
        [@default None] [@key "catalogEntry"]
    packagecontent : string option; [@default None] [@key "packageContent"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
