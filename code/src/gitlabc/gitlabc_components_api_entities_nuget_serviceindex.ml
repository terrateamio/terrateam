module Primary = struct
  module Resources = struct
    module Items = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    resources : Resources.t option; [@default None]
    version : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
