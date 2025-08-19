module Policies = struct
  type t = Terrat_repo_config_notification_policy.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { policies : Policies.t option [@default None] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
