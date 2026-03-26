module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "completed" -> Ok `Completed
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Completed -> `String "completed"

    type t = ([ `Completed ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Custom_pattern_scope = struct
    let t_of_yojson = function
      | `String "enterprise" -> Ok `Enterprise
      | `String "organization" -> Ok `Organization
      | `String "repository" -> Ok `Repository
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Enterprise -> `String "enterprise"
      | `Organization -> `String "organization"
      | `Repository -> `String "repository"

    type t =
      ([ `Enterprise
       | `Organization
       | `Repository
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Secret_types = struct
    type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Source = struct
    let t_of_yojson = function
      | `String "discussions" -> Ok `Discussions
      | `String "git" -> Ok `Git
      | `String "issues" -> Ok `Issues
      | `String "pull-requests" -> Ok `Pull_requests
      | `String "wiki" -> Ok `Wiki
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Discussions -> `String "discussions"
      | `Git -> `String "git"
      | `Issues -> `String "issues"
      | `Pull_requests -> `String "pull-requests"
      | `Wiki -> `String "wiki"

    type t =
      ([ `Discussions
       | `Git
       | `Issues
       | `Pull_requests
       | `Wiki
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Type = struct
    let t_of_yojson = function
      | `String "backfill" -> Ok `Backfill
      | `String "custom-pattern-backfill" -> Ok `Custom_pattern_backfill
      | `String "pattern-version-backfill" -> Ok `Pattern_version_backfill
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Backfill -> `String "backfill"
      | `Custom_pattern_backfill -> `String "custom-pattern-backfill"
      | `Pattern_version_backfill -> `String "pattern-version-backfill"

    type t =
      ([ `Backfill
       | `Custom_pattern_backfill
       | `Pattern_version_backfill
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
