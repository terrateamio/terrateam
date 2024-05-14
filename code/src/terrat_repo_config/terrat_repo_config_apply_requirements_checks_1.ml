type t = {
  approved : Terrat_repo_config_apply_requirements_checks_approved.t option; [@default None]
  merge_conflicts : Terrat_repo_config_apply_requirements_checks_merge_conflicts.t option;
      [@default None]
  status_checks : Terrat_repo_config_apply_requirements_checks_status_checks.t option;
      [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
