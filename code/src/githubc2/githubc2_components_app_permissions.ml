module Primary = struct
  module Actions = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Administration = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Checks = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Content_references = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Contents = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Deployments = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Environments = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Issues = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Members = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Metadata = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Organization_administration = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Organization_hooks = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Organization_packages = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Organization_plan = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Organization_projects = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | `String "admin" -> Ok "admin"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Organization_secrets = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Organization_self_hosted_runners = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Organization_user_blocking = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Packages = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Pages = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Pull_requests = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Repository_hooks = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Repository_projects = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | `String "admin" -> Ok "admin"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Secret_scanning_alerts = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Secrets = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Security_events = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Single_file = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Statuses = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Team_discussions = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Vulnerability_alerts = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Workflows = struct
    let t_of_yojson = function
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    actions : Actions.t option; [@default None]
    administration : Administration.t option; [@default None]
    checks : Checks.t option; [@default None]
    content_references : Content_references.t option; [@default None]
    contents : Contents.t option; [@default None]
    deployments : Deployments.t option; [@default None]
    environments : Environments.t option; [@default None]
    issues : Issues.t option; [@default None]
    members : Members.t option; [@default None]
    metadata : Metadata.t option; [@default None]
    organization_administration : Organization_administration.t option; [@default None]
    organization_hooks : Organization_hooks.t option; [@default None]
    organization_packages : Organization_packages.t option; [@default None]
    organization_plan : Organization_plan.t option; [@default None]
    organization_projects : Organization_projects.t option; [@default None]
    organization_secrets : Organization_secrets.t option; [@default None]
    organization_self_hosted_runners : Organization_self_hosted_runners.t option; [@default None]
    organization_user_blocking : Organization_user_blocking.t option; [@default None]
    packages : Packages.t option; [@default None]
    pages : Pages.t option; [@default None]
    pull_requests : Pull_requests.t option; [@default None]
    repository_hooks : Repository_hooks.t option; [@default None]
    repository_projects : Repository_projects.t option; [@default None]
    secret_scanning_alerts : Secret_scanning_alerts.t option; [@default None]
    secrets : Secrets.t option; [@default None]
    security_events : Security_events.t option; [@default None]
    single_file : Single_file.t option; [@default None]
    statuses : Statuses.t option; [@default None]
    team_discussions : Team_discussions.t option; [@default None]
    vulnerability_alerts : Vulnerability_alerts.t option; [@default None]
    workflows : Workflows.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
