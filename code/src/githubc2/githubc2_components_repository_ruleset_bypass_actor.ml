module Primary = struct
  module Actor_type = struct
    let t_of_yojson = function
      | `String "Integration" -> Ok "Integration"
      | `String "OrganizationAdmin" -> Ok "OrganizationAdmin"
      | `String "RepositoryRole" -> Ok "RepositoryRole"
      | `String "Team" -> Ok "Team"
      | `String "DeployKey" -> Ok "DeployKey"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Bypass_mode = struct
    let t_of_yojson = function
      | `String "always" -> Ok "always"
      | `String "pull_request" -> Ok "pull_request"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    actor_id : int option; [@default None]
    actor_type : Actor_type.t;
    bypass_mode : Bypass_mode.t; [@default "always"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
