module Apply = struct
  module Status_checks = struct
    type t = { enabled : bool [@default true] }
    [@@deriving yojson { strict = true; meta = true }, make, show, eq]
  end

  type t = {
    status_checks : Status_checks.t option; [@default None]
    visible_on : Terrat_repo_config_summary_visible_on.t option; [@default None]
  }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

module Plan = struct
  module Status_checks = struct
    type t = { enabled : bool [@default true] }
    [@@deriving yojson { strict = true; meta = true }, make, show, eq]
  end

  type t = {
    status_checks : Status_checks.t option; [@default None]
    visible_on : Terrat_repo_config_plan_visible_on.t option; [@default None]
  }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

module Policies = struct
  type t = Terrat_repo_config_notification_policy.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  apply : Apply.t option; [@default None]
  plan : Plan.t option; [@default None]
  policies : Policies.t option; [@default None]
  summary : Terrat_repo_config_notifications_summary.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
