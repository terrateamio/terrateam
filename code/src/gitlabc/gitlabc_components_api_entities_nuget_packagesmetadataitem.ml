module Primary = struct
  module Items = struct
    type t = Gitlabc_components_api_entities_nuget_packagemetadata.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    id_ : string option; [@default None] [@key "@id"]
    count : int option; [@default None]
    items : Items.t option; [@default None]
    lower : string option; [@default None]
    upper : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
