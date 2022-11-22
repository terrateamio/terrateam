module Policies = struct
  type t = Terrat_repo_config_access_control_policy.t list
  [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  apply_require_all_dirspace_access : bool; [@default true]
  enabled : bool; [@default true]
  plan_require_all_dirspace_access : bool; [@default false]
  policies : Policies.t option; [@default None]
  terrateam_config_update : Terrat_repo_config_access_control_match_list.t option; [@default None]
  unlock : Terrat_repo_config_access_control_match_list.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show]
