module Primary = struct
  module Dependencies = struct
    type t = Gitlabc_components_api_entities_nuget_dependency.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    id_ : string option; [@default None] [@key "@id"]
    type_ : string option; [@default None] [@key "@type"]
    dependencies : Dependencies.t option; [@default None]
    targetframework : string option; [@default None] [@key "targetFramework"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
