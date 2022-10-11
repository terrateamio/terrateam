module Primary = struct
  module Base_role = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "triage" -> Ok "triage"
      | `String "write" -> Ok "write"
      | `String "maintain" -> Ok "maintain"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Permissions = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    base_role : Base_role.t option; [@default None]
    created_at : string option; [@default None]
    description : string option; [@default None]
    id : int;
    name : string;
    organization : Githubc2_components_simple_user.t option; [@default None]
    permissions : Permissions.t option; [@default None]
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
