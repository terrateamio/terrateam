module Primary = struct
  module Extra = struct
    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
  end

  type t = {
    blob : string option; [@default None]
    context_project : string option; [@default None]
    context_sha : string option; [@default None]
    extra : Extra.t option; [@default None]
    location : string option; [@default None]
    raw : string option; [@default None]
    type_ : string option; [@default None] [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
