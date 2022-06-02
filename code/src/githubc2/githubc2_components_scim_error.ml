module Primary = struct
  module Schemas = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    detail : string option; [@default None]
    documentation_url : string option; [@default None]
    message : string option; [@default None]
    schemas : Schemas.t option; [@default None]
    scimtype : string option; [@default None] [@key "scimType"]
    status : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
