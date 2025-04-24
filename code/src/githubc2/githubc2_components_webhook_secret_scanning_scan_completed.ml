module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "completed" -> Ok "completed"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Custom_pattern_scope = struct
    let t_of_yojson = function
      | `String "repository" -> Ok "repository"
      | `String "organization" -> Ok "organization"
      | `String "enterprise" -> Ok "enterprise"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Secret_types = struct
    type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Source = struct
    let t_of_yojson = function
      | `String "git" -> Ok "git"
      | `String "issues" -> Ok "issues"
      | `String "pull-requests" -> Ok "pull-requests"
      | `String "discussions" -> Ok "discussions"
      | `String "wiki" -> Ok "wiki"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Type = struct
    let t_of_yojson = function
      | `String "backfill" -> Ok "backfill"
      | `String "custom-pattern-backfill" -> Ok "custom-pattern-backfill"
      | `String "pattern-version-backfill" -> Ok "pattern-version-backfill"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    completed_at : string;
    custom_pattern_name : string option; [@default None]
    custom_pattern_scope : Custom_pattern_scope.t option; [@default None]
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    secret_types : Secret_types.t option; [@default None]
    sender : Githubc2_components_simple_user.t option; [@default None]
    source : Source.t;
    started_at : string;
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
