module Primary = struct
  module Resources = struct
    type t = Githubc2_components_scim_user.t list
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Schemas = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    resources : Resources.t; [@key "Resources"]
    itemsperpage : int; [@key "itemsPerPage"]
    schemas : Schemas.t;
    startindex : int; [@key "startIndex"]
    totalresults : int; [@key "totalResults"]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
