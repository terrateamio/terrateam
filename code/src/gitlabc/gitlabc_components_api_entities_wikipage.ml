module Primary = struct
  module Front_matter = struct
    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
  end

  type t = {
    content : string option; [@default None]
    encoding : string option; [@default None]
    format : string option; [@default None]
    front_matter : Front_matter.t option; [@default None]
    slug : string option; [@default None]
    title : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
