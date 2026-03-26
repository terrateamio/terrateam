module Primary = struct
  module Base_role = struct
    let t_of_yojson = function
      | `String "admin" -> Ok `Admin
      | `String "maintain" -> Ok `Maintain
      | `String "read" -> Ok `Read
      | `String "triage" -> Ok `Triage
      | `String "write" -> Ok `Write
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Admin -> `String "admin"
      | `Maintain -> `String "maintain"
      | `Read -> `String "read"
      | `Triage -> `String "triage"
      | `Write -> `String "write"

    type t =
      ([ `Admin
       | `Maintain
       | `Read
       | `Triage
       | `Write
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Permissions = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Source = struct
    let t_of_yojson = function
      | `String "Enterprise" -> Ok `Enterprise
      | `String "Organization" -> Ok `Organization
      | `String "Predefined" -> Ok `Predefined
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Enterprise -> `String "Enterprise"
      | `Organization -> `String "Organization"
      | `Predefined -> `String "Predefined"

    type t =
      ([ `Enterprise
       | `Organization
       | `Predefined
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
