module Primary = struct
  module Actions = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Administration = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Checks = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Codespaces = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Contents = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Dependabot_secrets = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Deployments = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Email_addresses = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Environments = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Followers = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Git_ssh_keys = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Gpg_keys = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Interaction_limits = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Issues = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Members = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Metadata_ = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_administration = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_announcement_banners = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_copilot_seat_management = struct
    let t_of_yojson = function
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_custom_org_roles = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_custom_properties = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | `String "admin" -> Ok "admin"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_custom_roles = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_events = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_hooks = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_packages = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_personal_access_token_requests = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_personal_access_tokens = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_plan = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_projects = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | `String "admin" -> Ok "admin"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_secrets = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_self_hosted_runners = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Organization_user_blocking = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Packages = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Pages = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Profile = struct
    let t_of_yojson = function
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Pull_requests = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Repository_custom_properties = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Repository_hooks = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Repository_projects = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | `String "admin" -> Ok "admin"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Secret_scanning_alerts = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Secrets = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Security_events = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Single_file = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Starring = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Statuses = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Team_discussions = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Vulnerability_alerts = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Workflows = struct
    let t_of_yojson = function
      | `String "write" -> Ok "write"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    actions : Actions.t option; [@default None]
    administration : Administration.t option; [@default None]
    checks : Checks.t option; [@default None]
    codespaces : Codespaces.t option; [@default None]
    contents : Contents.t option; [@default None]
    dependabot_secrets : Dependabot_secrets.t option; [@default None]
    deployments : Deployments.t option; [@default None]
    email_addresses : Email_addresses.t option; [@default None]
    environments : Environments.t option; [@default None]
    followers : Followers.t option; [@default None]
    git_ssh_keys : Git_ssh_keys.t option; [@default None]
    gpg_keys : Gpg_keys.t option; [@default None]
    interaction_limits : Interaction_limits.t option; [@default None]
    issues : Issues.t option; [@default None]
    members : Members.t option; [@default None]
    metadata : Metadata_.t option; [@default None]
    organization_administration : Organization_administration.t option; [@default None]
    organization_announcement_banners : Organization_announcement_banners.t option; [@default None]
    organization_copilot_seat_management : Organization_copilot_seat_management.t option;
        [@default None]
    organization_custom_org_roles : Organization_custom_org_roles.t option; [@default None]
    organization_custom_properties : Organization_custom_properties.t option; [@default None]
    organization_custom_roles : Organization_custom_roles.t option; [@default None]
    organization_events : Organization_events.t option; [@default None]
    organization_hooks : Organization_hooks.t option; [@default None]
    organization_packages : Organization_packages.t option; [@default None]
    organization_personal_access_token_requests :
      Organization_personal_access_token_requests.t option;
        [@default None]
    organization_personal_access_tokens : Organization_personal_access_tokens.t option;
        [@default None]
    organization_plan : Organization_plan.t option; [@default None]
    organization_projects : Organization_projects.t option; [@default None]
    organization_secrets : Organization_secrets.t option; [@default None]
    organization_self_hosted_runners : Organization_self_hosted_runners.t option; [@default None]
    organization_user_blocking : Organization_user_blocking.t option; [@default None]
    packages : Packages.t option; [@default None]
    pages : Pages.t option; [@default None]
    profile : Profile.t option; [@default None]
    pull_requests : Pull_requests.t option; [@default None]
    repository_custom_properties : Repository_custom_properties.t option; [@default None]
    repository_hooks : Repository_hooks.t option; [@default None]
    repository_projects : Repository_projects.t option; [@default None]
    secret_scanning_alerts : Secret_scanning_alerts.t option; [@default None]
    secrets : Secrets.t option; [@default None]
    security_events : Security_events.t option; [@default None]
    single_file : Single_file.t option; [@default None]
    starring : Starring.t option; [@default None]
    statuses : Statuses.t option; [@default None]
    team_discussions : Team_discussions.t option; [@default None]
    vulnerability_alerts : Vulnerability_alerts.t option; [@default None]
    workflows : Workflows.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
