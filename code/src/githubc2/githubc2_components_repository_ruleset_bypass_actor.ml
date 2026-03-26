module Primary = struct
  module Actor_type = struct
    let t_of_yojson = function
      | `String "DeployKey" -> Ok `DeployKey
      | `String "Integration" -> Ok `Integration
      | `String "OrganizationAdmin" -> Ok `OrganizationAdmin
      | `String "RepositoryRole" -> Ok `RepositoryRole
      | `String "Team" -> Ok `Team
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `DeployKey -> `String "DeployKey"
      | `Integration -> `String "Integration"
      | `OrganizationAdmin -> `String "OrganizationAdmin"
      | `RepositoryRole -> `String "RepositoryRole"
      | `Team -> `String "Team"

    type t =
      ([ `DeployKey
       | `Integration
       | `OrganizationAdmin
       | `RepositoryRole
       | `Team
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Bypass_mode = struct
    let t_of_yojson = function
      | `String "always" -> Ok `Always
      | `String "pull_request" -> Ok `Pull_request
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Always -> `String "always"
      | `Pull_request -> `String "pull_request"

    type t =
      ([ `Always
       | `Pull_request
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    actor_id : int option; [@default None]
    actor_type : Actor_type.t;
    bypass_mode : Bypass_mode.t; [@default `Always]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
