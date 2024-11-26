module Items = struct
  type t = {
    approved : Terrat_repo_config_apply_requirements_checks_approved_2.t option; [@default None]
    merge_conflicts : Terrat_repo_config_apply_requirements_checks_merge_conflicts.t option;
        [@default None]
    require_ready_for_review_pr : bool; [@default true]
    status_checks : Terrat_repo_config_apply_requirements_checks_status_checks.t option;
        [@default None]
    tag_query : string;
  }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
