module Primary = struct
  module Conditions = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Limitations = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Permissions = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    conditions : Conditions.t option; [@default None]
    content : string option; [@default None]
    description : string option; [@default None]
    html_url : string option; [@default None]
    key : string option; [@default None]
    limitations : Limitations.t option; [@default None]
    name : string option; [@default None]
    nickname : string option; [@default None]
    permissions : Permissions.t option; [@default None]
    popular : bool option; [@default None]
    source_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
