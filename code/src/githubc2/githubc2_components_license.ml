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
    body : string;
    conditions : Conditions.t;
    description : string;
    featured : bool;
    html_url : string;
    implementation : string;
    key : string;
    limitations : Limitations.t;
    name : string;
    node_id : string;
    permissions : Permissions.t;
    spdx_id : string option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
