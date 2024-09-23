module Files = struct
  include
    Json_schema.Additional_properties.Make
      (Json_schema.Empty_obj)
      (Terrat_repo_config_access_control_match_list)
end

module Policies = struct
  type t = Terrat_repo_config_access_control_policy.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  apply_require_all_dirspace_access : bool; [@default true]
  ci_config_update : Terrat_repo_config_access_control_match_list.t option; [@default None]
  enabled : bool; [@default true]
  files : Files.t option; [@default None]
  plan_require_all_dirspace_access : bool; [@default false]
  policies : Policies.t option; [@default None]
  terrateam_config_update : Terrat_repo_config_access_control_match_list.t option; [@default None]
  unlock : Terrat_repo_config_access_control_match_list.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
