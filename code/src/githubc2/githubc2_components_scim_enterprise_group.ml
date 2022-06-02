module Primary = struct
  module Members = struct
    module Items = struct
      module Primary = struct
        type t = {
          ref_ : string option; [@default None] [@key "$ref"]
          display : string option; [@default None]
          value : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Meta = struct
    module Primary = struct
      type t = {
        created : string option; [@default None]
        lastmodified : string option; [@default None] [@key "lastModified"]
        location : string option; [@default None]
        resourcetype : string option; [@default None] [@key "resourceType"]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Schemas = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    displayname : string option; [@default None] [@key "displayName"]
    externalid : string option; [@default None] [@key "externalId"]
    id : string;
    members : Members.t option; [@default None]
    meta : Meta.t option; [@default None]
    schemas : Schemas.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
