module Primary = struct
  module Base_role = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "triage" -> Ok "triage"
      | `String "write" -> Ok "write"
      | `String "maintain" -> Ok "maintain"
      | `String "admin" -> Ok "admin"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Permissions = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Source = struct
    let t_of_yojson = function
      | `String "Organization" -> Ok "Organization"
      | `String "Enterprise" -> Ok "Enterprise"
      | `String "Predefined" -> Ok "Predefined"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    base_role : Base_role.t option; [@default None]
    created_at : string;
    description : string option; [@default None]
    id : int64;
    name : string;
    organization : Githubc2_components_nullable_simple_user.t option; [@default None]
    permissions : Permissions.t;
    source : Source.t option; [@default None]
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
