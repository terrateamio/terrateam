module Tmpl = struct
  module Transformers = struct
    let money =
      ( "money",
        Snabela.Kv.(
          function
          | F num -> S (Printf.sprintf "%01.02f" num)
          | any -> any) )

    let plan_diff =
      ( "plan_diff",
        Snabela.Kv.(
          function
          | S plan -> S (Terrat_plan_diff.transform plan)
          | any -> any) )

    let compact_plan =
      ( "compact_plan",
        Snabela.Kv.(
          function
          | S plan ->
              S
                (plan
                |> CCString.split_on_char '\n'
                |> CCList.filter (fun s -> CCString.find ~sub:"= (known after apply)" s = -1)
                |> CCString.concat "\n")
          | any -> any) )

    let minus_one =
      ( "minus_one",
        Snabela.Kv.(
          function
          | I v -> I (v - 1)
          | F v -> F (v -. 1.0)
          | any -> any) )
  end

  let read fname =
    fname
    |> Terrat_files_gitlab_tmpl.read
    |> CCOption.get_exn_or fname
    |> Snabela.Template.of_utf8_string
    |> (function
    | Ok tmpl -> tmpl
    | Error (#Snabela.Template.err as err) -> failwith (Snabela.Template.show_err err))
    |> fun tmpl ->
    Snabela.of_template tmpl Transformers.[ money; compact_plan; plan_diff; minus_one ]

  let jinja fname = fname |> Terrat_files_gitlab_tmpl.read |> CCOption.get_exn_or fname
  let terrateam_comment_help = read "terrateam_comment_help.tmpl"
  let apply_requirements_config_err_tag_query = read "apply_requirements_config_err_tag_query.tmpl"

  let apply_requirements_config_err_invalid_query =
    read "apply_requirements_config_err_invalid_query.tmpl"

  let apply_requirements_validation_err = read "apply_requirements_validation_err.tmpl"
  let mismatched_refs = read "mismatched_refs.tmpl"
  let missing_plans = read "missing_plans.tmpl"
  let dirspaces_owned_by_other_pull_requests = read "dirspaces_owned_by_other_pull_requests.tmpl"
  let conflicting_work_manifests = read "conflicting_work_manifests.tmpl"
  let synthesize_config_err_cycle = jinja "synthesize_config_err_cycle.tmpl"

  let synthesize_config_err_workspace_in_multiple_stacks =
    jinja "synthesize_config_err_workspace_in_multiple_stacks.tmpl"

  let synthesize_config_err_workspace_matches_no_stacks =
    jinja "synthesize_config_err_workspace_matches_no_stacks.tmpl"

  let synthesize_config_err_stack_not_found = jinja "synthesize_config_err_stack_not_found.tmpl"
  let str_template_err_missing_var = jinja "str_template_err_missing_var.tmpl"
  let maybe_stale_work_manifests = read "maybe_stale_work_manifests.tmpl"
  let repo_config_parse_failure = read "repo_config_parse_failure.tmpl"
  let repo_config_schema_err = read "repo_config_schema_err.tmpl"
  let repo_config_generic_failure = read "repo_config_generic_failure.tmpl"
  let pull_request_not_appliable = jinja "pull_request_not_appliable.tmpl"
  let pull_request_not_mergeable = read "pull_request_not_mergeable.tmpl"
  let apply_no_matching_dirspaces = read "apply_no_matching_dirspaces.tmpl"
  let plan_no_matching_dirspaces = read "plan_no_matching_dirspaces.tmpl"
  let base_branch_not_default_branch = read "dest_branch_no_match.tmpl"
  let auto_apply_running = read "auto_apply_running.tmpl"
  let bad_custom_branch_tag_pattern = read "bad_custom_branch_tag_pattern.tmpl"
  let bad_glob = read "bad_glob.tmpl"
  let unlock_success = read "unlock_success.tmpl"
  let access_control_all_dirspaces_denied = read "access_control_all_dirspaces_denied.tmpl"
  let access_control_dirspaces_denied = read "access_control_dirspaces_denied.tmpl"
  let access_control_files_denied = read "access_control_files_denied.tmpl"
  let access_control_unlock_denied = read "access_control_unlock_denied.tmpl"
  let access_control_ci_config_update_denied = read "access_control_ci_config_update_denied.tmpl"

  let access_control_terrateam_config_update_denied =
    read "access_control_terrateam_config_update_denied.tmpl"

  let access_control_lookup_err = read "access_control_lookup_err.tmpl"
  let tag_query_error = read "tag_query_error.tmpl"
  let account_expired_err = read "account_expired_err.tmpl"
  let repo_config = read "repo_config.tmpl"
  let unexpected_temporary_err = read "unexpected_temporary_err.tmpl"
  let failed_to_start_workflow = read "failed_to_start_workflow.tmpl"

  let failed_to_start_identity_verification_workflow =
    read "failed_to_start_identify_verification_workflow.tmpl"

  let failed_to_find_workflow = read "failed_to_find_workflow.tmpl"
  let comment_too_large = read "comment_too_large.tmpl"
  let index_complete = read "index_complete.tmpl"
  let invalid_lock_id = read "unlock_failed_bad_id.tmpl"

  (* Repo config errors *)
  let repo_config_err_access_control_policy_apply_autoapprove_match_parse_err =
    read "repo_config_err_access_control_policy_apply_autoapprove_match_parse_err.tmpl"

  let repo_config_err_access_control_policy_apply_force_match_parse_err =
    read "repo_config_err_access_control_policy_apply_force_match_parse_err.tmpl"

  let repo_config_err_access_control_policy_apply_match_parse_err =
    read "repo_config_err_access_control_policy_apply_match_parse_err.tmpl"

  let repo_config_err_access_control_policy_apply_with_superapproval_match_parse_err =
    read "repo_config_err_access_control_policy_apply_with_supperapproval_match_parse_err.tmpl"

  let repo_config_err_access_control_policy_plan_match_parse_err =
    read "repo_config_err_access_control_policy_plan_match_parse_err.tmpl"

  let repo_config_err_access_control_policy_superapproval_match_parse_err =
    read "repo_config_err_access_control_policy_superapproval_match_parse_err.tmpl"

  let repo_config_err_access_control_policy_tag_query_err =
    read "repo_config_err_access_control_policy_tag_query_err.tmpl"

  let repo_config_err_access_control_terrateam_config_update_match_parse_err =
    read "repo_config_err_access_control_terrateam_config_update_match_parse_err.tmpl"

  let repo_config_err_access_control_ci_config_update_match_parse_err =
    read "repo_config_err_access_control_ci_config_update_match_parse_err.tmpl"

  let repo_config_err_access_control_file_match_parse_err =
    read "repo_config_err_access_control_file_match_parse_err.tmpl"

  let repo_config_err_access_control_unlock_match_parse_err =
    read "repo_config_err_access_control_unlock_match_parse_err.tmpl"

  let repo_config_err_apply_requirements_approved_all_of_match_parse_err =
    read "repo_config_err_apply_requirements_approved_all_of_match_parse_err.tmpl"

  let repo_config_err_apply_requirements_approved_any_of_match_parse_err =
    read "repo_config_err_apply_requirements_approved_any_of_match_parse_err.tmpl"

  let repo_config_err_apply_requirements_check_tag_query_err =
    read "repo_config_err_apply_requirements_check_tag_query_err.tmpl"

  let repo_config_err_depends_on_err = read "repo_config_err_depends_on_err.tmpl"
  let repo_config_err_drift_schedule_err = read "repo_config_err_drift_schedule_err.tmpl"
  let repo_config_err_drift_tag_query_err = read "repo_config_err_drift_tag_query_err.tmpl"
  let repo_config_err_glob_parse_err = read "repo_config_err_glob_parse_err.tmpl"

  let repo_config_err_hooks_unknown_run_on_err =
    read "repo_config_err_hooks_unknown_run_on_err.tmpl"

  let repo_config_err_hooks_unknown_visible_on_err =
    read "repo_config_err_hooks_unknown_visible_on_err.tmpl"

  let repo_config_err_pattern_parse_err = read "repo_config_err_pattern_parse_err.tmpl"
  let repo_config_err_unknown_lock_policy_err = read "repo_config_err_unknown_lock_policy_err.tmpl"

  let repo_config_err_window_parse_timezone_err =
    read "repo_config_err_window_parse_timezone_err.tmpl"

  let repo_config_err_workflows_apply_unknown_run_on_err =
    read "repo_config_err_workflows_apply_unknown_run_on_err.tmpl"

  let repo_config_err_workflows_apply_unknown_visible_on_err =
    read "repo_config_err_workflows_apply_unknown_visible_on_err.tmpl"

  let repo_config_err_workflows_plan_unknown_run_on_err =
    read "repo_config_err_workflows_plan_unknown_run_on_err.tmpl"

  let repo_config_err_workflows_plan_unknown_visible_on_err =
    read "repo_config_err_workflows_plan_unknown_visible_on_err.tmpl"

  let repo_config_err_workflows_tag_query_parse_err =
    read "repo_config_err_workflows_tag_query_parse_err.tmpl"

  let plan_complete = read "plan_complete.tmpl"
  let apply_complete = read "apply_complete.tmpl"
  let plan_complete2 = jinja "plan_complete2.tmpl"
  let apply_complete2 = jinja "apply_complete2.tmpl"
  let automerge_failure = read "automerge_error.tmpl"
  let premium_feature_err_access_control = read "premium_feature_err_access_control.tmpl"

  let premium_feature_err_multiple_drift_schedules =
    read "premium_feature_err_multiple_drift_schedules.tmpl"

  let premium_feature_err_gatekeeping = read "premium_feature_err_gatekeeping.tmpl"

  let premium_feature_err_require_completed_reviews =
    read "premium_feature_err_require_completed_reviews.tmpl"

  let repo_config_merge_err = read "repo_config_merge_err.tmpl"
  let gate_check_failure = jinja "gate_check_failure.tmpl"
  let tier_check = read "tier_check.tmpl"
  let build_tree_failure = read "build_tree_failure.tmpl"
  let notification_policy_tag_query_err = jinja "notification_policy_tag_query_err.tmpl"
end

module Ui = struct
  let work_manifest_url config account = raise (Failure "nyi")
end
