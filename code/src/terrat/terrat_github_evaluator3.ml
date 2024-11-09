let fetch_pull_request_tries = 6
let fetch_file_length_of_git_hash = CCString.length "aa2022e256fc3435d05d9d8ca0ef0ad0805e6ea5"
let not_a_bad_chunk_size = 500

let probably_is_git_hash =
  CCString.for_all (function
      | '0' .. '9' | 'a' .. 'f' -> true
      | _ -> false)

module Metrics = struct
  module DefaultHistogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_list [ 0.005; 0.5; 1.0; 5.0; 10.0; 15.0; 20.0 ]
  end)

  module Work_manifest_run_time_histogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_exponential 20.0 1.5 10
  end)

  module Run_output_histogram = Prmths.Histogram (struct
    let spec =
      Prmths.Histogram_spec.of_list [ 500.0; 1000.0; 2500.0; 10000.0; 20000.0; 35000.0; 65000.0 ]
  end)

  let namespace = "terrat"
  let subsystem = "github_evaluator"
  let pgsql_errors_total = Terrat_metrics.errors_total ~m:subsystem ~t:"pgsql"

  let cache_fn_call_count =
    let help = "Count of cache calls by function with hit or miss" in
    let family =
      Prmths.Counter.v_labels
        ~label_names:[ "lifetime"; "fn"; "type" ]
        ~help
        ~namespace
        ~subsystem
        "cache_fn_call_count"
    in
    fun ~l ~fn t -> Prmths.Counter.labels family [ l; fn; t ]

  let github_errors_total = Terrat_metrics.errors_total ~m:subsystem ~t:"github"

  let fetch_pull_request_errors_total =
    let help = "Number of errors in fetching a pull request" in
    Prmths.Counter.v ~help ~namespace ~subsystem "fetch_pull_request_errors_total"

  let pull_request_mergeable_state_count =
    let help = "Counts for the different mergeable states in pull requests fetches" in
    Prmths.Counter.v_label
      ~label_name:"mergeable_state"
      ~help
      ~namespace
      ~subsystem
      "pull_request_mergeable_state_count"

  let run_overall_result_count =
    let help = "Count of the results of overall runs" in
    Prmths.Counter.v_label
      ~label_name:"success"
      ~help
      ~namespace
      ~subsystem
      "run_overall_result_count"
end

module Sql = struct
  let read fname =
    CCOption.get_exn_or
      fname
      (CCOption.map
         (fun s ->
           s
           |> CCString.split_on_char '\n'
           |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
           |> CCString.concat "\n")
         (Terrat_files_sql.read fname))

  let base64 = function
    | Some s :: rest -> (
        match Base64.decode (CCString.replace ~sub:"\n" ~by:"" s) with
        | Ok s -> Some (s, rest)
        | _ -> None)
    | _ -> None

  let policy =
    let module P = struct
      type t = Terrat_base_repo_config_v1.Access_control.Match_list.t [@@deriving yojson]
    end in
    CCFun.(
      CCOption.wrap Yojson.Safe.from_string
      %> CCOption.map P.of_yojson
      %> CCOption.flat_map CCResult.to_opt)

  let lock_policy = function
    | Terrat_base_repo_config_v1.Workflows.Entry.Lock_policy.Apply -> "apply"
    | Terrat_base_repo_config_v1.Workflows.Entry.Lock_policy.Merge -> "merge"
    | Terrat_base_repo_config_v1.Workflows.Entry.Lock_policy.None -> "none"
    | Terrat_base_repo_config_v1.Workflows.Entry.Lock_policy.Strict -> "strict"

  let insert_github_installation_repository =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_installation_repository.sql"
      /% Var.bigint "id"
      /% Var.bigint "installation_id"
      /% Var.text "owner"
      /% Var.text "name")

  let select_installation_account_status () =
    Pgsql_io.Typed_sql.(
      sql
      // (* account_status *) Ret.text
      /^ "select account_status from github_installations where id = $installation_id"
      /% Var.bigint "installation_id")

  let insert_pull_request =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_pull_request.sql"
      /% Var.text "base_branch"
      /% Var.text "base_sha"
      /% Var.text "branch"
      /% Var.bigint "pull_number"
      /% Var.bigint "repository"
      /% Var.text "sha"
      /% Var.(option (text "merged_sha"))
      /% Var.(option (timestamptz "merged_at"))
      /% Var.text "state"
      /% Var.(option (text "title"))
      /% Var.(option (text "username")))

  let select_index =
    let index =
      CCFun.(
        CCOption.wrap Yojson.Safe.from_string
        %> CCOption.map Terrat_code_idx.of_yojson
        %> CCOption.flat_map CCResult.to_opt)
    in
    Pgsql_io.Typed_sql.(
      sql
      // (* Index *) Ret.(ud' index)
      /^ "select index from github_code_index where sha = $sha and installation_id = \
          $installation_id"
      /% Var.bigint "installation_id"
      /% Var.text "sha")

  let select_repo_config =
    Pgsql_io.Typed_sql.(
      sql
      // (* repo_config *) Ret.ud' (CCOption.wrap Yojson.Safe.from_string)
      /^ "select github_repo_configs.data from github_repo_configs where sha = $sha and \
          installation_id = $installation_id"
      /% Var.bigint "installation_id"
      /% Var.text "sha")

  let insert_repo_config =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_repo_configs (installation_id, sha, data) values($installation_id, \
          $sha, $data) on conflict (installation_id, sha) do update set data = excluded.data"
      /% Var.bigint "installation_id"
      /% Var.text "sha"
      /% Var.json "data")

  let cleanup_repo_configs =
    Pgsql_io.Typed_sql.(
      sql /^ "delete from github_repo_configs where (now() - created_at) > interval '1 day'")

  let select_work_manifest_dirspaceflows =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workflow_idx *) Ret.(option smallint)
      // (* workspace *) Ret.text
      /^ "select path, workflow_idx, workspace from github_work_manifest_dirspaceflows where \
          work_manifest = $id"
      /% Var.uuid "id")

  let insert_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.uuid
      // (* state *) Ret.ud' Terrat_work_manifest3.State.of_string
      // (* created_at *) Ret.text
      /^ read "insert_github_work_manifest.sql"
      /% Var.text "base_sha"
      /% Var.(option (bigint "pull_number"))
      /% Var.bigint "repository"
      /% Var.text "run_type"
      /% Var.text "sha"
      /% Var.text "tag_query"
      /% Var.(option (text "username"))
      /% Var.json "dirspaces"
      /% Var.text "run_kind"
      /% Var.(option (text "environment")))

  let insert_drift_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_drift_work_manifests (work_manifest, branch) values($work_manifest, \
          $branch)"
      /% Var.uuid "work_manifest"
      /% Var.text "branch")

  let select_drift_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      // (* branch *) Ret.text
      // (* reconcile *) Ret.boolean
      /^ read "select_github_drift_work_manifest.sql"
      /% Var.uuid "work_manifest")

  let update_work_manifest_state_running () =
    Pgsql_io.Typed_sql.(
      sql /^ "update github_work_manifests set state = 'running' where id = $id" /% Var.uuid "id")

  let update_work_manifest_state_completed () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_work_manifests set state = 'completed', completed_at = now() where id = $id"
      /% Var.uuid "id")

  let update_work_manifest_state_aborted () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_work_manifests set state = 'aborted', completed_at = now() where id = $id"
      /% Var.uuid "id")

  let update_work_manifest_run_id () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_work_manifests set run_id = $run_id where id = $id"
      /% Var.uuid "id"
      /% Var.(option (text "run_id")))

  let insert_work_manifest_dirspaceflow () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_work_manifest_dirspaceflows (work_manifest, path, workspace, \
          workflow_idx) select * from unnest($work_manifest, $path, $workspace, $workflow_idx) on \
          conflict (path, workspace, work_manifest) do nothing"
      /% Var.(str_array (uuid "work_manifest"))
      /% Var.(str_array (text "path"))
      /% Var.(str_array (text "workspace"))
      /% Var.(array (option (smallint "workflow_idx"))))

  let insert_work_manifest_access_control_denied_dirspace =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_work_manifest_access_control_denied_dirspace.sql"
      /% Var.(str_array (text "path"))
      /% Var.(str_array (text "workspace"))
      /% Var.(str_array (option (json "policy")))
      /% Var.(str_array (uuid "work_manifest")))

  let update_run_type =
    Pgsql_io.Typed_sql.(
      sql
      /^ "update github_work_manifests set run_type = $run_type where id = $id"
      /% Var.uuid "id"
      /% Var.text "run_type")

  let select_work_manifest () =
    Pgsql_io.Typed_sql.(
      sql
      // (* base_sha *) Ret.text
      // (* completed_at *) Ret.(option text)
      // (* created_at *) Ret.text
      // (* pull_number *) Ret.(option bigint)
      // (* repository *) Ret.bigint
      // (* run_id *) Ret.(option text)
      // (* run_type *) Ret.(ud' Terrat_work_manifest3.Step.of_string)
      // (* sha *) Ret.text
      // (* state *) Ret.(ud' Terrat_work_manifest3.State.of_string)
      // (* tag_query *) Ret.(ud' CCFun.(Terrat_tag_query.of_string %> CCResult.to_opt))
      // (* username *) Ret.(option text)
      // (* run_kind *) Ret.text
      // (* installation_id *) Ret.bigint
      // (* repo_id *) Ret.bigint
      // (* repo_owner *) Ret.text
      // (* repo_name *) Ret.text
      // (* environment *) Ret.(option text)
      /^ read "select_github_work_manifest2.sql"
      /% Var.uuid "id")

  let select_work_manifest_access_control_denied_dirspaces =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      // (* policy *) Ret.(option (ud' policy))
      /^ read "select_github_work_manifest_access_control_denied_dirspaces.sql"
      /% Var.uuid "work_manifest")

  let select_work_manifest_pull_request () =
    Pgsql_io.Typed_sql.(
      sql
      // (* base_branch_name *) Ret.text
      // (* base_ref *) Ret.text
      // (* branch_name *) Ret.text
      // (* branch_ref *) Ret.text
      // (* pull_number *) Ret.bigint
      // (* state *) Ret.text
      // (* merged_sha *) Ret.(option text)
      // (* merged_at *) Ret.(option text)
      // (* title *) Ret.(option text)
      // (* username *) Ret.(option text)
      /^ read "select_github_work_manifest_pull_request.sql"
      /% Var.uuid "id")

  let select_next_work_manifest =
    Pgsql_io.Typed_sql.(sql // (* id *) Ret.uuid /^ read "select_next_github_work_manifest.sql")

  let insert_index () =
    Pgsql_io.Typed_sql.(
      sql /^ read "github_insert_code_index.sql" /% Var.uuid "work_manifest" /% Var.json "index")

  let upsert_flow_state () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into flow_states (id, data, updated_at) values($id, $data, now()) on conflict \
          (id) do update set (data, updated_at) = (excluded.data, excluded.updated_at)"
      /% Var.uuid "id"
      /% Var.text "data")

  let select_flow_state () =
    Pgsql_io.Typed_sql.(
      sql
      // (* data *) Ret.text
      /^ "select data from flow_states where id = $id for update"
      /% Var.uuid "id")

  let delete_stale_flow_states () =
    Pgsql_io.Typed_sql.(
      sql /^ "delete from flow_states where (now() - updated_at) > interval '1 day'")

  let delete_flow_state () =
    Pgsql_io.Typed_sql.(sql /^ "delete from flow_states where id = $id" /% Var.uuid "id")

  let insert_pull_request_unlock () =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_pull_request_unlock.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number")

  let insert_drift_unlock () =
    Pgsql_io.Typed_sql.(sql /^ read "insert_github_drift_unlock.sql" /% Var.bigint "repository")

  let select_out_of_diff_applies =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      /^ read "select_github_out_of_diff_applies.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number")

  let select_dirspace_applies_for_pull_request =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      /^ read "select_github_dirspace_applies_for_pull_request.sql"
      /% Var.bigint "repo_id"
      /% Var.bigint "pull_number")

  let select_dirspaces_without_valid_plans =
    Pgsql_io.Typed_sql.(
      sql
      // (* dir *) Ret.text
      // (* workspace *) Ret.text
      /^ read "select_github_dirspaces_without_valid_plans.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number"
      /% Var.(str_array (text "dirs"))
      /% Var.(str_array (text "workspaces")))

  let insert_dirspace =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_dirspaces.sql"
      /% Var.(str_array (text "base_sha"))
      /% Var.(str_array (text "path"))
      /% Var.(array (bigint "repository"))
      /% Var.(str_array (text "sha"))
      /% Var.(str_array (text "workspace"))
      /% Var.(str_array (ud (text "lock_policy") lock_policy)))

  let select_recent_plan =
    Pgsql_io.Typed_sql.(
      sql
      // (* data *) Ret.ud base64
      /^ read "select_github_recent_plan.sql"
      /% Var.uuid "id"
      /% Var.text "dir"
      /% Var.text "workspace")

  let delete_plan () =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "delete_github_terraform_plan.sql"
      /% Var.uuid "id"
      /% Var.text "dir"
      /% Var.text "workspace")

  let delete_old_plans = Pgsql_io.Typed_sql.(sql /^ read "delete_github_old_terraform_plans.sql")

  let upsert_plan =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "upsert_terraform_plan.sql"
      /% Var.uuid "work_manifest"
      /% Var.text "path"
      /% Var.text "workspace"
      /% Var.(ud (text "data") Base64.encode_string))

  let insert_github_work_manifest_result =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_work_manifest_result.sql"
      /% Var.uuid "work_manifest"
      /% Var.text "path"
      /% Var.text "workspace"
      /% Var.boolean "success")

  let update_abort_duplicate_work_manifests () =
    Pgsql_io.Typed_sql.(
      sql
      // (* work manifest id *) Ret.uuid
      /^ read "github_abort_duplicate_work_manifests.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number"
      /% Var.(ud (text "run_type") Terrat_work_manifest3.Step.to_string)
      /% Var.(str_array (text "dirs"))
      /% Var.(str_array (text "workspaces")))

  let select_conflicting_work_manifests_in_repo () =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.uuid
      // (* maybe_stale *) Ret.boolean
      /^ read "select_github_conflicting_work_manifests_in_repo2.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number"
      /% Var.(ud (text "run_type") Terrat_work_manifest3.Step.to_string)
      /% Var.(str_array (text "dirs"))
      /% Var.(str_array (text "workspaces")))

  let select_dirspaces_owned_by_other_pull_requests () =
    Pgsql_io.Typed_sql.(
      sql
      // (* dir *) Ret.text
      // (* workspace *) Ret.text
      // (* base_branch *) Ret.text
      // (* branch *) Ret.text
      // (* base_hash *) Ret.text
      // (* hash *) Ret.text
      // (* merged_hash *) Ret.(option text)
      // (* merged_at *) Ret.(option text)
      // (* pull_number *) Ret.bigint
      // (* state *) Ret.text
      // (* title *) Ret.(option text)
      // (* username *) Ret.(option text)
      /^ read "select_github_dirspaces_owned_by_other_pull_requests.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number"
      /% Var.(str_array (text "dirs"))
      /% Var.(str_array (text "workspaces")))

  let upsert_drift_schedule =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "github_upsert_drift_schedule.sql"
      /% Var.bigint "repo"
      /% Var.(ud (text "schedule") Terrat_base_repo_config_v1.Drift.Schedule.to_string)
      /% Var.boolean "reconcile"
      /% Var.(option (ud (text "tag_query") Terrat_tag_query.to_string)))

  let delete_drift_schedule =
    Pgsql_io.Typed_sql.(
      sql
      /^ "delete from github_drift_schedules where repository = $repo_id"
      /% Var.bigint "repo_id")

  let select_missing_drift_scheduled_runs () =
    Pgsql_io.Typed_sql.(
      sql
      // (* installation_id *) Ret.bigint
      // (* repository *) Ret.bigint
      // (* owner *) Ret.text
      // (* name *) Ret.text
      // (* reconcile *) Ret.boolean
      // (* tag_query *) Ret.(option (ud' CCFun.(Terrat_tag_query.of_string %> CCResult.to_opt)))
      /^ read "github_select_missing_drift_scheduled_runs.sql")
end

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
  end

  let read fname =
    fname
    |> Terrat_files_tmpl.read
    |> CCOption.get_exn_or fname
    |> Snabela.Template.of_utf8_string
    |> (function
         | Ok tmpl -> tmpl
         | Error (#Snabela.Template.err as err) -> failwith (Snabela.Template.show_err err))
    |> fun tmpl -> Snabela.of_template tmpl Transformers.[ money; compact_plan; plan_diff ]

  let terrateam_comment_help = read "terrateam_comment_help.tmpl"

  let apply_requirements_config_err_tag_query =
    read "github_apply_requirements_config_err_tag_query.tmpl"

  let apply_requirements_config_err_invalid_query =
    read "github_apply_requirements_config_err_invalid_query.tmpl"

  let apply_requirements_validation_err = read "github_apply_requirements_validation_err.tmpl"
  let mismatched_refs = read "github_mismatched_refs.tmpl"
  let missing_plans = read "github_missing_plans.tmpl"

  let dirspaces_owned_by_other_pull_requests =
    read "github_dirspaces_owned_by_other_pull_requests.tmpl"

  let conflicting_work_manifests = read "github_conflicting_work_manifests.tmpl"
  let depends_on_cycle = read "github_depends_on_cycle.tmpl"
  let maybe_stale_work_manifests = read "github_maybe_stale_work_manifests.tmpl"
  let repo_config_parse_failure = read "github_repo_config_parse_failure.tmpl"
  let repo_config_generic_failure = read "github_repo_config_generic_failure.tmpl"
  let pull_request_not_appliable = read "github_pull_request_not_appliable.tmpl"
  let pull_request_not_mergeable = read "github_pull_request_not_mergeable.tmpl"
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
  let failed_to_start_workflow = read "github_failed_to_start_workflow.tmpl"
  let failed_to_find_workflow = read "github_failed_to_find_workflow.tmpl"

  let comment_too_large =
    "github_comment_too_large.tmpl"
    |> Terrat_files_tmpl.read
    |> CCOption.get_exn_or "github_comment_too_large.tmpl"

  let index_complete = read "github_index_complete.tmpl"
  let invalid_lock_id = read "github_unlock_failed_bad_id.tmpl"

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

  let repo_config_err_pattern_parse_err = read "repo_config_err_pattern_parse_err.tmpl"
  let repo_config_err_unknown_lock_policy_err = read "repo_config_err_unknown_lock_policy_err.tmpl"

  let repo_config_err_workflows_apply_unknown_run_on_err =
    read "repo_config_err_workflows_apply_unknown_run_on_err.tmpl"

  let repo_config_err_workflows_plan_unknown_run_on_err =
    read "repo_config_err_workflows_plan_unknown_run_on_err.tmpl"

  let repo_config_err_workflows_tag_query_parse_err =
    read "repo_config_err_workflows_tag_query_parse_err.tmpl"

  let plan_complete = read "github_plan_complete.tmpl"
  let apply_complete = read "github_apply_complete.tmpl"
end

module S = struct
  module Account = struct
    type t = { installation_id : int } [@@deriving make, yojson, eq]

    let make ~installation_id () = { installation_id }
    let id t = t.installation_id
    let to_string t = CCInt.to_string t.installation_id
  end

  module Ref = struct
    type t = string [@@deriving eq, yojson]

    let to_string = CCFun.id
    let of_string = CCFun.id
  end

  module Repo = struct
    type t = {
      id : int;
      name : string;
      owner : string;
    }
    [@@deriving eq, yojson]

    let id t = t.id
    let make ~id ~name ~owner () = { id; name; owner }
    let name t = t.name
    let owner t = t.owner
    let to_string t = t.owner ^ "/" ^ t.name
  end

  module Remote_repo = struct
    module R = Githubc2_components.Full_repository
    module U = Githubc2_components.Simple_user

    type t = R.t [@@deriving yojson]

    let to_repo
        {
          R.primary =
            { R.Primary.id; owner = { U.primary = { U.Primary.login = owner; _ }; _ }; name; _ };
          _;
        } =
      Repo.make ~id ~owner ~name ()

    let default_branch t = t.R.primary.R.Primary.default_branch
  end

  module User = struct
    type t = string [@@deriving yojson]

    let make = CCFun.id
    let to_string = CCFun.id
  end

  module Pull_request = struct
    module Diff = struct
      type t = Terrat_change.Diff.t =
        | Add of { filename : string }
        | Change of { filename : string }
        | Remove of { filename : string }
        | Move of {
            filename : string;
            previous_filename : string;
          }
      [@@deriving yojson]
    end

    module State = struct
      module Merged = struct
        type t = Terrat_pull_request.State.Merged.t = {
          merged_hash : string;
          merged_at : string;
        }
        [@@deriving show, yojson]
      end

      module Open_status = struct
        type t = Terrat_pull_request.State.Open_status.t =
          | Mergeable
          | Merge_conflict
        [@@deriving show, yojson]
      end

      type t = Terrat_pull_request.State.t =
        | Open of Open_status.t
        | Closed
        | Merged of Merged.t
      [@@deriving show, yojson]
    end

    type fetched = {
      checks : bool;
      diff : Diff.t list;
      is_draft_pr : bool;
      mergeable : bool option;
      provisional_merge_ref : Ref.t option;
    }
    [@@deriving yojson]

    type stored = unit [@@deriving yojson]

    type 'a t = {
      base_branch_name : Ref.t;
      base_ref : Ref.t;
      branch_name : Ref.t;
      branch_ref : Ref.t;
      id : int;
      repo : Repo.t;
      state : State.t;
      title : string option;
      user : string option;
      value : 'a;
    }
    [@@deriving yojson]

    let base_branch_name t = t.base_branch_name
    let base_ref t = t.base_ref
    let branch_name t = t.branch_name
    let branch_ref t = t.branch_ref
    let diff t = t.value.diff
    let id t = t.id
    let is_draft_pr t = t.value.is_draft_pr
    let provisional_merge_ref t = t.value.provisional_merge_ref
    let repo t = t.repo
    let state t = t.state
    let stored_of_fetched t = { t with value = () }
  end

  module Client = struct
    let on_hit fn () = Prmths.Counter.inc_one (Metrics.cache_fn_call_count ~l:"global" ~fn "hit")
    let on_miss fn () = Prmths.Counter.inc_one (Metrics.cache_fn_call_count ~l:"global" ~fn "miss")

    module Client_cache = Abb_cache.Expiring.Make (struct
      type k = Account.t [@@deriving eq]
      type v = Githubc2_abb.t
      type err = [ `Error ]
      type args = unit -> (v, err) result Abb.Future.t

      let fetch f = f ()
    end)

    module Fetch_file_cache = struct
      module M = struct
        type k = Account.t * Repo.t * Ref.t * string [@@deriving eq]
        type v = Githubc2_components.Content_file.t option
        type err = Terrat_github.fetch_file_err
        type args = unit -> (v, err) result Abb.Future.t

        let fetch f = f ()
      end

      module By_rev = Abb_cache.Lru.Make (M)
    end

    module Fetch_repo_cache = Abb_cache.Expiring.Make (struct
      type k = Account.t * (string * string) [@@deriving eq]
      type v = Remote_repo.t
      type err = Terrat_github.fetch_repo_err
      type args = unit -> (v, err) result Abb.Future.t

      let fetch f = f ()
    end)

    module Fetch_tree_cache = struct
      module M = struct
        type k = Account.t * Repo.t * Ref.t [@@deriving eq]
        type v = string list
        type err = Terrat_github.get_tree_err
        type args = unit -> (v, err) result Abb.Future.t

        let fetch f = f ()
      end

      module By_rev = Abb_cache.Lru.Make (M)
    end

    module Globals = struct
      let client_cache =
        Client_cache.create
          {
            Abb_cache.Expiring.on_hit = on_hit "create_client";
            on_miss = on_miss "create_client";
            duration = Duration.of_sec 60;
            size = 10;
          }

      let fetch_file_by_rev_cache =
        Fetch_file_cache.By_rev.create
          {
            Abb_cache.Lru.on_hit = on_hit "fetch_file_by_rev";
            on_miss = on_miss "fetch_file_by_rev";
            size = 100;
          }

      let fetch_repo_cache =
        Fetch_repo_cache.create
          {
            Abb_cache.Expiring.on_hit = on_hit "fetch_repo";
            on_miss = on_miss "fetch_repo";
            duration = Duration.of_sec 60;
            size = 100;
          }

      let fetch_tree_by_rev_cache =
        Fetch_tree_cache.By_rev.create
          {
            Abb_cache.Lru.on_hit = on_hit "fetch_tree_by_rev";
            on_miss = on_miss "fetch_tree_by_rev";
            size = 100;
          }
    end

    type t = {
      account : Account.t;
      client : Githubc2_abb.t;
      config : Terrat_config.t;
      fetch_file_by_rev_cache : Fetch_file_cache.By_rev.t;
      fetch_repo_cache : Fetch_repo_cache.t;
      fetch_tree_by_rev_cache : Fetch_tree_cache.By_rev.t;
    }

    let make ~account ~client ~config () =
      {
        account;
        client;
        config;
        fetch_file_by_rev_cache = Globals.fetch_file_by_rev_cache;
        fetch_repo_cache = Globals.fetch_repo_cache;
        fetch_tree_by_rev_cache = Globals.fetch_tree_by_rev_cache;
      }
  end

  let fetch_branch_sha ~request_id client repo ref_ =
    let ret =
      let open Abbs_future_combinators.Infix_result_monad in
      let module B = Githubc2_components.Branch_with_protection in
      let module C = Githubc2_components.Commit in
      Terrat_github.fetch_branch
        ~owner:repo.Repo.owner
        ~repo:repo.Repo.name
        ~branch:ref_
        client.Client.client
      >>= fun { B.primary = { B.Primary.commit = { C.primary = { C.Primary.sha; _ }; _ }; _ }; _ } ->
      Abb.Future.return (Ok sha)
    in
    let open Abb.Future.Infix_monad in
    ret
    >>= function
    | Ok sha -> Abb.Future.return (Ok (Some sha))
    | Error (`Not_found _) -> Abb.Future.return (Ok None)
    | Error (#Terrat_github.fetch_branch_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : FETCH_BRANCH_SHA : %a"
              request_id
              Terrat_github.pp_fetch_branch_err
              err);
        Abb.Future.return (Error `Error)

  let fetch_file ~request_id client repo ref_ path =
    let module C = Githubc2_components.Content_file in
    let open Abb.Future.Infix_monad in
    (* If we think the reference looks like a git hash, we know that the content
       of the file will never change, so we cache that in an LRU cache.
       Otherwise, we use an expiring cache. *)
    let fetch () =
      Terrat_github.fetch_file
        ~owner:repo.Repo.owner
        ~repo:repo.Repo.name
        ~ref_
        ~path
        client.Client.client
    in
    (if CCString.length ref_ = fetch_file_length_of_git_hash && probably_is_git_hash ref_ then
       Client.Fetch_file_cache.By_rev.fetch
         client.Client.fetch_file_by_rev_cache
         (client.Client.account, repo, ref_, path)
         fetch
     else fetch ())
    >>= function
    | Ok (Some { C.primary = { C.Primary.encoding = "base64"; content; _ }; _ }) ->
        Abb.Future.return
          (Ok (Some (Base64.decode_exn (CCString.replace ~sub:"\n" ~by:"" content))))
    | Ok (Some { C.primary = { C.Primary.content; _ }; _ }) -> Abb.Future.return (Ok (Some content))
    | Ok None -> Abb.Future.return (Ok None)
    | Error (#Terrat_github.fetch_file_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : FETCH_FILE : %a"
              request_id
              Terrat_github.pp_fetch_file_err
              err);
        Abb.Future.return (Error `Error)

  let fetch_remote_repo ~request_id client repo =
    let open Abb.Future.Infix_monad in
    let fetch () =
      Terrat_github.fetch_repo ~owner:repo.Repo.owner ~repo:repo.Repo.name client.Client.client
    in
    Client.Fetch_repo_cache.fetch
      client.Client.fetch_repo_cache
      (client.Client.account, (Repo.owner repo, Repo.name repo))
      fetch
    >>= function
    | Ok _ as r -> Abb.Future.return r
    | Error (#Terrat_github.fetch_repo_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : FETCH_REMOTE_REPO : %a"
              request_id
              Terrat_github.pp_fetch_repo_err
              err);
        Abb.Future.return (Error `Error)

  let fetch_centralized_repo ~request_id client owner =
    let centralized_repo_name = "terrateam" in
    let open Abb.Future.Infix_monad in
    let fetch () =
      Terrat_github.fetch_repo ~owner ~repo:centralized_repo_name client.Client.client
    in
    Client.Fetch_repo_cache.fetch
      client.Client.fetch_repo_cache
      (client.Client.account, (owner, centralized_repo_name))
      fetch
    >>= function
    | Ok r -> Abb.Future.return (Ok (Some r))
    | Error (`Not_found _) -> Abb.Future.return (Ok None)
    | Error (#Terrat_github.fetch_repo_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : FETCH_CENTRALIZED_REPO : %a"
              request_id
              Terrat_github.pp_fetch_repo_err
              err);
        Abb.Future.return (Error `Error)

  let repo_config_of_json json =
    match Terrat_repo_config.Version_1.of_yojson json with
    | Ok config -> Abb.Future.return (Terrat_base_repo_config_v1.of_version_1 config)
    | Error err ->
        (* This is a cheap trick but we just want to make the error
           message a - little bit more friendly to users by replacing the
           parts of the - error message that are specific to the
           implementation. *)
        Abb.Future.return
          (Error
             (`Repo_config_parse_err
               ("Failed to parse repo config: "
               ^ (err
                 |> CCString.replace ~sub:"Terrat_repo_config." ~by:""
                 |> CCString.replace ~sub:".t" ~by:""
                 |> CCString.lowercase_ascii))))
end

module Make
    (Terratc : Terratc_intf.S
                 with type Github.Client.t = S.Client.t
                  and type Github.Account.t = S.Account.t
                  and type Github.Repo.t = S.Repo.t
                  and type Github.Ref.t = S.Ref.t) =
struct
  module S = struct
    include S

    module Drift = struct
      type t
    end

    module Access_control = Terratc.Github.Access_control

    let create_access_control_ctx ~request_id client config repo user =
      Access_control.Ctx.make ~client:client.Client.client ~config ~repo ~user ()

    module Apply_requirements = struct
      module Result = struct
        type t = {
          approved : bool option;
          approved_reviews : Terrat_pull_request_review.t list;
          match_ : Terrat_change_match3.Dirspace_config.t;
          merge_conflicts : bool option;
          passed : bool;
          status_checks : bool option;
          status_checks_failed : Terrat_commit_check.t list;
        }
      end

      type t = Result.t list

      let passed t = CCList.for_all (fun { Result.passed; _ } -> passed) t

      let approved_reviews t =
        CCList.flatten (CCList.map (fun { Result.approved_reviews; _ } -> approved_reviews) t)
    end

    let make_run_telemetry config step repo =
      let module Wm = Terrat_work_manifest3 in
      Terrat_telemetry.Event.Run
        {
          github_app_id = Terrat_config.github_app_id config;
          step;
          owner = repo.Repo.owner;
          repo = repo.Repo.name;
        }

    let query_work_manifest ~request_id db work_manifest_id =
      let module Wm = Terrat_work_manifest3 in
      let module Dsf = Terrat_change.Dirspaceflow in
      let module Ds = Terrat_change.Dirspace in
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_work_manifest_dirspaceflows
          ~f:(fun dir idx workspace -> { Dsf.dirspace = { Ds.dir; workspace }; workflow = idx })
          work_manifest_id
        >>= fun changes ->
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_work_manifest_access_control_denied_dirspaces
          ~f:(fun dir workspace policy ->
            { Wm.Deny.dirspace = { Terrat_change.Dirspace.dir; workspace }; policy })
          work_manifest_id
        >>= fun denied_dirspaces ->
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.select_work_manifest ())
          ~f:(fun
              base_ref
              completed_at
              created_at
              pull_request_id
              repository
              run_id
              run_type
              branch_ref
              state
              tag_query
              user
              run_kind
              installation_id
              repo_id
              owner
              name
              environment
            ->
            {
              Wm.account = Account.make ~installation_id:(CCInt64.to_int installation_id) ();
              base_ref;
              branch_ref;
              changes;
              completed_at;
              created_at;
              denied_dirspaces;
              environment;
              id = work_manifest_id;
              initiator =
                (match user with
                | Some user -> Wm.Initiator.User user
                | None -> Wm.Initiator.System);
              run_id;
              steps = [ run_type ];
              state;
              tag_query;
              target =
                ( CCOption.map CCInt64.to_int pull_request_id,
                  Repo.make ~id:(CCInt64.to_int repo_id) ~owner ~name () );
            })
          work_manifest_id
        >>= function
        | [] -> Abb.Future.return (Ok None)
        | wm :: _ -> (
            match wm.Wm.target with
            | Some pull_request_id, repo -> (
                Pgsql_io.Prepared_stmt.fetch
                  db
                  (Sql.select_work_manifest_pull_request ())
                  ~f:(fun
                      base_branch_name
                      base_ref
                      branch_name
                      branch_ref
                      pull_number
                      state
                      merged_sha
                      merged_at
                      title
                      user
                    ->
                    {
                      Pull_request.base_branch_name;
                      base_ref;
                      branch_name;
                      branch_ref;
                      id = CCInt64.to_int pull_number;
                      repo;
                      state =
                        (match (state, merged_sha, merged_at) with
                        | "open", _, _ -> Pull_request.State.(Open Open_status.Mergeable)
                        | "closed", _, _ -> Pull_request.State.Closed
                        | "merged", Some merged_hash, Some merged_at ->
                            Pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                        | _ -> assert false);
                      title;
                      user;
                      value = ();
                    })
                  work_manifest_id
                >>= function
                | [] -> assert false
                | pr :: _ ->
                    Abb.Future.return
                      (Ok (Some { wm with Wm.target = Terrat_evaluator3.Target.Pr pr })))
            | None, repo -> (
                Pgsql_io.Prepared_stmt.fetch
                  db
                  (Sql.select_drift_work_manifest ())
                  ~f:(fun branch _ -> branch)
                  work_manifest_id
                >>= function
                | [] -> assert false
                | branch :: _ ->
                    Abb.Future.return
                      (Ok
                         (Some
                            { wm with Wm.target = Terrat_evaluator3.Target.Drift { repo; branch } }))
                ))
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let create_client' config { Account.installation_id } =
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.get_installation_access_token config installation_id
      >>= fun access_token ->
      let github_client = Terrat_github.create config (`Token access_token) in
      Abb.Future.return (Ok github_client)

    let create_client ~request_id config account =
      let open Abb.Future.Infix_monad in
      let fetch () =
        create_client' config account
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error (#Terrat_github.get_installation_access_token_err as err) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVALUATOR : %s: ERROR : %a"
                  request_id
                  Terrat_github.pp_get_installation_access_token_err
                  err);
            Abb.Future.return (Error `Error)
      in
      Client.Client_cache.fetch Client.Globals.client_cache account fetch
      >>= function
      | Ok github_client ->
          Abb.Future.return (Ok (Client.make ~account ~client:github_client ~config ()))
      | Error `Error -> Abb.Future.return (Error `Error)

    let store_account_repository ~request_id db account repo =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.execute
        db
        Sql.insert_github_installation_repository
        (CCInt64.of_int (Repo.id repo))
        (CCInt64.of_int account.Account.installation_id)
        (Repo.owner repo)
        (Repo.name repo)
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let query_account_status ~request_id db account =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.fetch
        db
        (Sql.select_installation_account_status ())
        ~f:CCFun.id
        (CCInt64.of_int account.Account.installation_id)
      >>= function
      | Ok ("expired" :: _) -> Abb.Future.return (Ok `Expired)
      | Ok ("disabled" :: _) -> Abb.Future.return (Ok `Disabled)
      | Ok _ -> Abb.Future.return (Ok `Active)
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let store_pull_request ~request_id db pull_request =
      let open Abb.Future.Infix_monad in
      let module Pr = Pull_request in
      let module State = Pr.State in
      let merged_sha, merged_at, state =
        match pull_request.Pr.state with
        | State.Open _ -> (None, None, "open")
        | State.Closed -> (None, None, "closed")
        | State.(Merged { Merged.merged_hash; merged_at }) ->
            (Some merged_hash, Some merged_at, "merged")
      in
      Pgsql_io.Prepared_stmt.execute
        db
        Sql.insert_pull_request
        pull_request.Pr.base_branch_name
        pull_request.Pr.base_ref
        pull_request.Pr.branch_name
        (CCInt64.of_int pull_request.Pr.id)
        (CCInt64.of_int pull_request.Pr.repo.Repo.id)
        pull_request.Pr.branch_ref
        merged_sha
        merged_at
        state
        pull_request.Pr.title
        pull_request.Pr.user
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let fetch_tree ~request_id client repo ref_ =
      let open Abb.Future.Infix_monad in
      let fetch () =
        Terrat_github.get_tree
          ~owner:repo.Repo.owner
          ~repo:repo.Repo.name
          ~sha:ref_
          client.Client.client
      in
      (if CCString.length ref_ = fetch_file_length_of_git_hash && probably_is_git_hash ref_ then
         Client.Fetch_tree_cache.By_rev.fetch
           client.Client.fetch_tree_by_rev_cache
           (client.Client.account, repo, ref_)
           fetch
       else fetch ())
      >>= function
      | Ok _ as r -> Abb.Future.return r
      | Error (#Terrat_github.get_tree_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : FETCH_TREE : %a"
                request_id
                Terrat_github.pp_get_tree_err
                err);
          Abb.Future.return (Error `Error)

    let index_of_index idx =
      let module Idx = Terrat_code_idx in
      let module Paths = Terrat_api_components.Work_manifest_index_paths in
      let module Symlinks = Terrat_api_components.Work_manifest_index_symlinks in
      let success = idx.Idx.success in
      let paths = Json_schema.String_map.to_list (Paths.additional idx.Idx.paths) in
      let symlinks =
        CCOption.map_or
          ~default:[]
          (fun idx -> Json_schema.String_map.to_list (Symlinks.additional idx))
          idx.Idx.symlinks
      in
      let failures =
        CCList.flat_map
          (fun (_path, { Paths.Additional.failures; _ }) ->
            let failures =
              Json_schema.String_map.to_list (Paths.Additional.Failures.additional failures)
            in
            CCList.map
              (fun (path, { Paths.Additional.Failures.Additional.lnum; msg }) ->
                { Terrat_evaluator3.Index.Failure.file = path; line_num = lnum; error = msg })
              failures)
          paths
      in
      let index =
        Terrat_base_repo_config_v1.Index.make
          ~symlinks
          (CCList.map
             (fun (path, { Paths.Additional.modules; _ }) ->
               (path, CCList.map (fun m -> Terrat_base_repo_config_v1.Index.Dep.Module m) modules))
             paths)
      in
      { Terrat_evaluator3.Index.success; failures; index }

    let query_index ~request_id db account ref_ =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_index
        ~f:CCFun.id
        (CCInt64.of_int account.Account.installation_id)
        ref_
      >>= function
      | Ok (idx :: _) -> Abb.Future.return (Ok (Some (index_of_index idx)))
      | Ok [] -> Abb.Future.return (Ok None)
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let store_index ~request_id db work_manifest_id index =
      let module R = Terrat_api_components.Work_manifest_index_result in
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.execute
        db
        (Sql.insert_index ())
        work_manifest_id
        (Yojson.Safe.to_string (R.to_yojson index))
      >>= function
      | Ok () -> Abb.Future.return (Ok (index_of_index index))
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let store_index_result ~request_id db work_manifest_id index =
      let module Wm = Terrat_work_manifest3 in
      let module Idx = Terrat_code_idx in
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        let success = index.Idx.success in
        query_work_manifest ~request_id db work_manifest_id
        >>= function
        | Some { Wm.changes; _ } ->
            Abbs_future_combinators.List_result.iter
              ~f:(fun dsf ->
                let module Ds = Terrat_change.Dirspace in
                let { Ds.dir; workspace } = Terrat_change.Dirspaceflow.to_dirspace dsf in
                Pgsql_io.Prepared_stmt.execute
                  db
                  Sql.insert_github_work_manifest_result
                  work_manifest_id
                  dir
                  workspace
                  success)
              changes
        | None -> assert false
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)
      | Error `Error -> Abb.Future.return (Error `Error)

    let query_repo_config_json ~request_id db account ref_ =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_repo_config
        ~f:CCFun.id
        (CCInt64.of_int account.Account.installation_id)
        ref_
      >>= function
      | Ok (repo_config :: _) -> Abb.Future.return (Ok (Some repo_config))
      | Ok [] -> Abb.Future.return (Ok None)
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let store_repo_config_json ~request_id db account ref_ repo_config =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.execute
        db
        Sql.insert_repo_config
        (CCInt64.of_int account.Account.installation_id)
        ref_
        (Yojson.Safe.to_string repo_config)
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let cleanup_repo_configs ~request_id db =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.execute db Sql.cleanup_repo_configs
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    module Result_publisher = struct
      module Workflow_step_output = struct
        type t = {
          success : bool;
          key : string option;
          text : string;
          step_type : string;
          details : string option;
        }
      end

      let maybe_credential_error_strings =
        [
          "no valid credential";
          "Required token could not be found";
          "could not find default credentials";
        ]

      let pre_hook_output_texts outputs =
        let module Output = Terrat_api_components_hook_outputs.Pre.Items in
        let module Text = Terrat_api_components_output_text in
        let module Run = Terrat_api_components_workflow_output_run in
        let module Checkout = Terrat_api_components_workflow_output_checkout in
        let module Ce = Terrat_api_components_workflow_output_cost_estimation in
        let module Oidc = Terrat_api_components_workflow_output_oidc in
        outputs
        |> CCList.filter_map (function
               | Output.Workflow_output_run
                   Run.
                     {
                       workflow_step = Workflow_step.{ type_; cmd; _ };
                       outputs = Some Text.{ text; output_key };
                       success;
                       _;
                     } ->
                   Some
                     Workflow_step_output.
                       {
                         key = output_key;
                         text;
                         success;
                         step_type = type_;
                         details = Some (CCString.concat " " cmd);
                       }
               | Output.Workflow_output_oidc
                   Oidc.
                     {
                       workflow_step = Workflow_step.{ type_; _ };
                       outputs = Some Text.{ text; output_key };
                       success;
                       _;
                     }
               | Output.Workflow_output_checkout
                   Checkout.
                     {
                       workflow_step = Workflow_step.{ type_; _ };
                       outputs = Text.{ text; output_key };
                       success;
                     }
               | Output.Workflow_output_cost_estimation
                   Ce.
                     {
                       workflow_step = Workflow_step.{ type_; _ };
                       outputs = Outputs.Output_text Text.{ text; output_key };
                       success;
                       _;
                     } ->
                   Some
                     Workflow_step_output.
                       { key = output_key; text; success; step_type = type_; details = None }
               | Output.Workflow_output_run
                   Run.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ }
               | Output.Workflow_output_oidc
                   Oidc.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ }
                 ->
                   Some
                     Workflow_step_output.
                       { key = None; text = ""; success; step_type = type_; details = None }
               | Output.Workflow_output_env _
               | Output.Workflow_output_cost_estimation
                   Ce.{ outputs = Outputs.Output_cost_estimation _; _ } -> None)

      let post_hook_output_texts (outputs : Terrat_api_components_hook_outputs.Post.t) =
        let module Output = Terrat_api_components_hook_outputs.Post.Items in
        let module Text = Terrat_api_components_output_text in
        let module Run = Terrat_api_components_workflow_output_run in
        let module Oidc = Terrat_api_components_workflow_output_oidc in
        let module Drift_create_issue = Terrat_api_components_workflow_output_drift_create_issue in
        outputs
        |> CCList.filter_map (function
               | Output.Workflow_output_run
                   Run.
                     {
                       workflow_step = Workflow_step.{ type_; cmd; _ };
                       outputs = Some Text.{ text; output_key };
                       success;
                       _;
                     } ->
                   Some
                     Workflow_step_output.
                       {
                         key = output_key;
                         text;
                         success;
                         step_type = type_;
                         details = Some (CCString.concat " " cmd);
                       }
               | Output.Workflow_output_oidc
                   Oidc.
                     {
                       workflow_step = Workflow_step.{ type_; _ };
                       outputs = Some Text.{ text; output_key };
                       success;
                       _;
                     }
               | Output.Workflow_output_drift_create_issue
                   Drift_create_issue.
                     {
                       workflow_step = Workflow_step.{ type_; _ };
                       outputs = Some Text.{ text; output_key };
                       success;
                       _;
                     } ->
                   Some
                     Workflow_step_output.
                       { key = output_key; text; success; step_type = type_; details = None }
               | Output.Workflow_output_run
                   Run.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ }
               | Output.Workflow_output_oidc
                   Oidc.{ workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ }
               | Output.Workflow_output_drift_create_issue
                   Drift_create_issue.
                     { workflow_step = Workflow_step.{ type_; _ }; outputs = None; success; _ } ->
                   Some
                     Workflow_step_output.
                       { key = None; text = ""; success; step_type = type_; details = None }
               | Output.Workflow_output_env _ -> None)

      let workflow_output_texts outputs =
        let module Output = Terrat_api_components_workflow_outputs.Items in
        let module Run = Terrat_api_components_workflow_output_run in
        let module Init = Terrat_api_components_workflow_output_init in
        let module Plan = Terrat_api_components_workflow_output_plan in
        let module Apply = Terrat_api_components_workflow_output_apply in
        let module Text = Terrat_api_components_output_text in
        let module Output_plan = Terrat_api_components_output_plan in
        let module Oidc = Terrat_api_components_workflow_output_oidc in
        outputs
        |> CCList.flat_map (function
               | Output.Workflow_output_run
                   Run.
                     {
                       workflow_step = Workflow_step.{ type_; cmd; _ };
                       outputs = Some Text.{ text; output_key };
                       success;
                       _;
                     } ->
                   [
                     Workflow_step_output.
                       {
                         key = output_key;
                         text;
                         success;
                         step_type = type_;
                         details = Some (CCString.concat " " cmd);
                       };
                   ]
               | Output.Workflow_output_oidc
                   Oidc.
                     {
                       workflow_step = Workflow_step.{ type_; _ };
                       outputs = Some Text.{ text; output_key };
                       success;
                       _;
                     }
               | Output.Workflow_output_init
                   Init.
                     {
                       workflow_step = Workflow_step.{ type_; _ };
                       outputs = Some Text.{ text; output_key };
                       success;
                       _;
                     }
               | Output.Workflow_output_plan
                   Plan.
                     {
                       workflow_step = Workflow_step.{ type_; _ };
                       outputs = Some (Plan.Outputs.Output_text Text.{ text; output_key });
                       success;
                       _;
                     }
               | Output.Workflow_output_apply
                   Apply.
                     {
                       workflow_step = Workflow_step.{ type_; _ };
                       outputs = Some Text.{ text; output_key };
                       success;
                       _;
                     } ->
                   [
                     Workflow_step_output.
                       { step_type = type_; text; key = output_key; success; details = None };
                   ]
               | Output.Workflow_output_plan
                   Plan.
                     {
                       workflow_step = Workflow_step.{ type_; _ };
                       outputs = Some (Plan.Outputs.Output_plan Output_plan.{ plan; plan_text; _ });
                       success;
                       _;
                     } ->
                   [
                     Workflow_step_output.
                       {
                         step_type = type_;
                         text = plan_text;
                         key = Some "plan_text";
                         success;
                         details = None;
                       };
                     Workflow_step_output.
                       {
                         step_type = type_;
                         text = plan;
                         key = Some "plan";
                         success;
                         details = None;
                       };
                   ]
               | Output.Workflow_output_run _
               | Output.Workflow_output_oidc _
               | Output.Workflow_output_plan _
               | Output.Workflow_output_env _
               | Output.Workflow_output_init Init.{ outputs = None; _ }
               | Output.Workflow_output_apply Apply.{ outputs = None; _ } -> [])

      let has_changes_of_workflow_outputs outputs =
        let module Output = Terrat_api_components_workflow_outputs.Items in
        let module Plan = Terrat_api_components_workflow_output_plan in
        let module Output_plan = Terrat_api_components_output_plan in
        (* Find the plan output, and then extract the has changes if it's there *)
        outputs
        |> CCList.find_opt (function
               | Output.Workflow_output_plan _ -> true
               | _ -> false)
        |> CCOption.flat_map (function
               | Output.Workflow_output_plan
                   Plan.
                     { outputs = Some (Plan.Outputs.Output_plan Output_plan.{ has_changes; _ }); _ }
                 -> Some has_changes
               | _ -> None)

      let create_run_output
          ~view
          request_id
          is_layered_run
          remaining_dirspace_configs
          results
          work_manifest =
        let module Wm = Terrat_work_manifest3 in
        let module Wmr = Terrat_api_components.Work_manifest_dirspace_result in
        let module R = Terrat_api_components_work_manifest_tf_operation_result in
        let dirspaces =
          let module Cmp = struct
            type t = bool * bool * string * string [@@deriving ord]
          end in
          results.R.dirspaces
          |> CCList.sort
               (fun
                 Wmr.{ path = p1; workspace = w1; success = s1; outputs = outputs1; _ }
                 Wmr.{ path = p2; workspace = w2; success = s2; outputs = outputs2; _ }
               ->
                 (* Sort the results by dirspace and whether or not it has
                    changes.  We want those dirspaces that have no changes
                    last. *)
                 let has_changes1 =
                   CCOption.get_or ~default:true (has_changes_of_workflow_outputs outputs1)
                 in
                 let has_changes2 =
                   CCOption.get_or ~default:true (has_changes_of_workflow_outputs outputs2)
                 in
                 (* Negate has_changes because the order of [bool] is [false]
                    before [true]. *)
                 Cmp.compare (not has_changes1, s1, p1, w1) (not has_changes2, s2, p2, w2))
        in
        let maybe_credentials_error =
          dirspaces
          |> CCList.exists (fun Wmr.{ outputs; _ } ->
                 let module Text = Terrat_api_components_output_text in
                 let texts = workflow_output_texts outputs in
                 CCList.exists
                   (fun Workflow_step_output.{ text; _ } ->
                     CCList.exists
                       (fun sub -> CCString.find ~sub text <> -1)
                       maybe_credential_error_strings)
                   texts)
        in
        let module Hook_outputs = Terrat_api_components.Hook_outputs in
        let pre = results.R.overall.R.Overall.outputs.Hook_outputs.pre in
        let post = results.R.overall.R.Overall.outputs.Hook_outputs.post in
        let cost_estimation =
          let module Wce = Terrat_api_components_workflow_output_cost_estimation in
          let module Ce = Terrat_api_components_output_cost_estimation in
          pre
          |> CCList.filter_map (function
                 | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_cost_estimation
                     {
                       Wce.outputs = Wce.Outputs.Output_cost_estimation Ce.{ cost_estimation; _ };
                       success = true;
                       _;
                     } -> Some cost_estimation
                 | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_run _
                 | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_oidc _
                 | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_env _
                 | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_checkout _
                 | Terrat_api_components.Hook_outputs.Pre.Items.Workflow_output_cost_estimation _ ->
                     None)
          |> CCOption.of_list
          |> CCOption.map (function
                 | Ce.Cost_estimation.
                     {
                       currency;
                       total_monthly_cost;
                       prev_monthly_cost;
                       diff_monthly_cost;
                       dirspaces;
                     }
                 ->
                 Snabela.Kv.(
                   Map.of_list
                     [
                       ("prev_monthly_cost", float prev_monthly_cost);
                       ("total_monthly_cost", float total_monthly_cost);
                       ("diff_monthly_cost", float diff_monthly_cost);
                       ("currency", string currency);
                       ( "dirspaces",
                         list
                           (CCList.map
                              (fun Ce.Cost_estimation.Dirspaces.Items.
                                     {
                                       path;
                                       workspace;
                                       total_monthly_cost;
                                       prev_monthly_cost;
                                       diff_monthly_cost;
                                     } ->
                                Map.of_list
                                  [
                                    ("dir", string path);
                                    ("workspace", string workspace);
                                    ("prev_monthly_cost", float prev_monthly_cost);
                                    ("total_monthly_cost", float total_monthly_cost);
                                    ("diff_monthly_cost", float diff_monthly_cost);
                                  ])
                              dirspaces) );
                     ]))
        in
        let kv_of_workflow_step steps =
          Snabela.Kv.(
            list
              (CCList.map
                 (fun Workflow_step_output.{ key; text; success; step_type; details } ->
                   Map.of_list
                     (CCList.concat
                        [
                          [
                            ("text", string text);
                            ("success", bool success);
                            ("step_type", string step_type);
                          ]
                          @ CCOption.map_or ~default:[] (fun key -> [ (key, bool true) ]) key
                          @ CCOption.map_or
                              ~default:[]
                              (fun details ->
                                [
                                  ( "details",
                                    string
                                      (match step_type with
                                      | "run" -> "`" ^ details ^ "`"
                                      | _ -> details) );
                                ])
                              details;
                        ]))
                 steps))
        in
        let num_remaining_layers = CCList.length remaining_dirspace_configs in
        let kv =
          Snabela.Kv.(
            Map.of_list
              (CCList.flatten
                 [
                   CCOption.map_or
                     ~default:[]
                     (fun cost_estimation -> [ ("cost_estimation", list [ cost_estimation ]) ])
                     cost_estimation;
                   CCOption.map_or
                     ~default:[]
                     (fun env -> [ ("environment", string env) ])
                     work_manifest.Wm.environment;
                   [
                     ("is_layered_run", bool is_layered_run);
                     ("is_last_layer", bool (num_remaining_layers = 0));
                     ("num_more_layers", int num_remaining_layers);
                     ("maybe_credentials_error", bool maybe_credentials_error);
                     ("overall_success", bool results.R.overall.R.Overall.success);
                     ("pre_hooks", kv_of_workflow_step (pre_hook_output_texts pre));
                     ("post_hooks", kv_of_workflow_step (post_hook_output_texts post));
                     ("compact_view", bool (view = `Compact));
                     ("compact_dirspaces", bool (CCList.length dirspaces > 5));
                     ( "results",
                       list
                         (CCList.map
                            (fun Wmr.{ path; workspace; success; outputs; _ } ->
                              let module Text = Terrat_api_components_output_text in
                              Map.of_list
                                (CCList.flatten
                                   [
                                     [
                                       ("dir", string path);
                                       ("workspace", string workspace);
                                       ("success", bool success);
                                       ( "outputs",
                                         kv_of_workflow_step (workflow_output_texts outputs) );
                                     ]
                                     @ CCOption.map_or
                                         ~default:[]
                                         (fun has_changes -> [ ("has_changes", bool has_changes) ])
                                         (has_changes_of_workflow_outputs outputs);
                                   ]))
                            dirspaces) );
                   ];
                   (match work_manifest.Wm.denied_dirspaces with
                   | [] -> []
                   | dirspaces ->
                       [
                         ( "denied_dirspaces",
                           list
                             (CCList.map
                                (fun {
                                       Wm.Deny.dirspace = { Terrat_change.Dirspace.dir; workspace };
                                       policy;
                                     } ->
                                  Map.of_list
                                    (CCList.flatten
                                       [
                                         [ ("dir", string dir); ("workspace", string workspace) ];
                                         (match policy with
                                         | Some policy ->
                                             [
                                               ( "policy",
                                                 list
                                                   (CCList.map
                                                      (fun p ->
                                                        Map.of_list
                                                          [
                                                            ( "item",
                                                              string
                                                                (Terrat_base_repo_config_v1
                                                                 .Access_control
                                                                 .Match
                                                                 .to_string
                                                                   p) );
                                                          ])
                                                      policy) );
                                             ]
                                         | None -> []);
                                       ]))
                                dirspaces) );
                       ]);
                 ]))
        in
        let tmpl =
          match CCList.rev work_manifest.Wm.steps with
          | [] | Wm.Step.Index :: _ | Wm.Step.Build_config :: _ -> assert false
          | Wm.Step.Plan :: _ -> Tmpl.plan_complete
          | Wm.Step.(Apply | Unsafe_apply) :: _ -> Tmpl.apply_complete
        in
        match Snabela.apply tmpl kv with
        | Ok body -> body
        | Error (#Snabela.err as err) ->
            Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Snabela.pp_err err);
            assert false

      let rec iterate_comment_posts
          ?(view = `Full)
          request_id
          client
          is_layered_run
          remaining_layers
          results
          pull_request
          work_manifest =
        let module Wm = Terrat_work_manifest3 in
        let output =
          create_run_output ~view request_id is_layered_run remaining_layers results work_manifest
        in
        let repo = pull_request.Pull_request.repo in
        let open Abb.Future.Infix_monad in
        Terrat_github.publish_comment
          ~owner:repo.Repo.owner
          ~repo:repo.Repo.name
          ~pull_number:pull_request.Pull_request.id
          ~body:output
          client.Client.client
        >>= function
        | Ok () -> Abb.Future.return (Ok ())
        | Error (#Terrat_github.publish_comment_err as err) -> (
            match
              (view, results.Terrat_api_components_work_manifest_tf_operation_result.dirspaces)
            with
            | _, [] -> assert false
            | `Full, _ ->
                Prmths.Counter.inc_one Metrics.github_errors_total;
                Logs.info (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : ITERATE_COMMENT_POST : %s"
                      request_id
                      (Terrat_github.show_publish_comment_err err));
                iterate_comment_posts
                  ~view:`Compact
                  request_id
                  client
                  is_layered_run
                  remaining_layers
                  results
                  pull_request
                  work_manifest
            | `Compact, [ _ ] ->
                (* If we're in compact view but there is only one dirspace, then
                   that means there is no way to make the comment smaller. *)
                Prmths.Counter.inc_one Metrics.github_errors_total;
                Logs.info (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : ITERATE_COMMENT_POST : %s"
                      request_id
                      (Terrat_github.show_publish_comment_err err));
                Terrat_github.publish_comment
                  ~owner:repo.Repo.owner
                  ~repo:repo.Repo.name
                  ~pull_number:pull_request.Pull_request.id
                  ~body:Tmpl.comment_too_large
                  client.Client.client
            | `Compact, dirspaces ->
                Abbs_future_combinators.List_result.iter
                  ~f:(fun dirspace ->
                    Prmths.Counter.inc_one Metrics.github_errors_total;
                    Logs.info (fun m ->
                        m
                          "GITHUB_EVALUATOR : %s : ITERATE_COMMENT_POST : %s"
                          request_id
                          (Terrat_github.show_publish_comment_err err));
                    let results =
                      {
                        results with
                        Terrat_api_components_work_manifest_tf_operation_result.dirspaces =
                          [ dirspace ];
                      }
                    in
                    iterate_comment_posts
                      ~view:`Full
                      request_id
                      client
                      is_layered_run
                      remaining_layers
                      results
                      pull_request
                      work_manifest)
                  dirspaces)
    end

    let publish_comment ~request_id client pull_request msg_type body =
      let open Abb.Future.Infix_monad in
      Terrat_github.publish_comment
        ~owner:(Repo.owner (Pull_request.repo pull_request))
        ~repo:(Repo.name (Pull_request.repo pull_request))
        ~pull_number:(Pull_request.id pull_request)
        ~body
        client.Client.client
      >>= function
      | Ok () ->
          Logs.info (fun m ->
              m "GITHUB_EVALUATOR : %s : PUBLISHED_COMMENT : %s" request_id msg_type);
          Abb.Future.return (Ok ())
      | Error (#Terrat_github.publish_comment_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : %s : ERROR : %a"
                request_id
                msg_type
                Terrat_github.pp_publish_comment_err
                err);
          Abb.Future.return (Error `Error)

    let apply_template_and_publish ~request_id client pull_request msg_type template kv =
      match Snabela.apply template kv with
      | Ok body -> publish_comment ~request_id client pull_request msg_type body
      | Error (#Snabela.err as err) ->
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : TEMPLATE_ERROR : %a" request_id Snabela.pp_err err);
          Abb.Future.return (Error `Error)

    let repo_config_failure ~request_id ~client ~pull_request ~title err =
      (* A bit of a cheap trick here to make it look like a code section in this
         context *)
      let err = "```\n" ^ err ^ "\n```" in
      let kv = Snabela.Kv.(Map.of_list [ ("title", string title); ("msg", string err) ]) in
      apply_template_and_publish
        ~request_id
        client
        pull_request
        "REPO_CONFIG_GENERIC_FAILURE"
        Tmpl.repo_config_generic_failure
        kv

    let repo_config_err ~request_id ~client ~pull_request ~title err =
      match err with
      | `Access_control_ci_config_update_match_parse_err m ->
          let kv = Snabela.Kv.(Map.of_list [ ("match", string m) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_CI_CONFIG_UPDATE_MATCH_PARSE_ERR"
            Tmpl.repo_config_err_access_control_ci_config_update_match_parse_err
            kv
      | `Access_control_file_match_parse_err (path, m) ->
          let kv = Snabela.Kv.(Map.of_list [ ("path", string path); ("match", string m) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_FILE_MATCH_PARSE_ERR"
            Tmpl.repo_config_err_access_control_file_match_parse_err
            kv
      | `Access_control_policy_apply_autoapprove_match_parse_err m ->
          let kv = Snabela.Kv.(Map.of_list [ ("match", string m) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_POLICY_APPLY_AUTOAPPROVE_MATCH_PARSE_ERR"
            Tmpl.repo_config_err_access_control_policy_apply_autoapprove_match_parse_err
            kv
      | `Access_control_policy_apply_force_match_parse_err m ->
          let kv = Snabela.Kv.(Map.of_list [ ("match", string m) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_POLICY_APPLY_FORCE_MATCH_PARSE_ERR"
            Tmpl.repo_config_err_access_control_policy_apply_force_match_parse_err
            kv
      | `Access_control_policy_apply_match_parse_err m ->
          let kv = Snabela.Kv.(Map.of_list [ ("match", string m) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_POLICY_APPLY_MATCH_PARSE_ERR"
            Tmpl.repo_config_err_access_control_policy_apply_match_parse_err
            kv
      | `Access_control_policy_apply_with_superapproval_match_parse_err m ->
          let kv = Snabela.Kv.(Map.of_list [ ("match", string m) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_POLICY_APPLY_WITH_SUPERAPPROVAL_MATCH_PARSE_ERR"
            Tmpl.repo_config_err_access_control_policy_apply_with_superapproval_match_parse_err
            kv
      | `Access_control_policy_plan_match_parse_err m ->
          let kv = Snabela.Kv.(Map.of_list [ ("match", string m) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_POLICY_PLAN_MATCH_PARSE_ERR"
            Tmpl.repo_config_err_access_control_policy_plan_match_parse_err
            kv
      | `Access_control_policy_superapproval_match_parse_err m ->
          let kv = Snabela.Kv.(Map.of_list [ ("match", string m) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_POLICY_SUPERAPPROVAL_MATCH_PARSE_ERR"
            Tmpl.repo_config_err_access_control_policy_superapproval_match_parse_err
            kv
      | `Access_control_policy_tag_query_err (q, err) ->
          let kv = Snabela.Kv.(Map.of_list [ ("query", string q); ("error", string err) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_POLICY_TAG_QUERY_ERR"
            Tmpl.repo_config_err_access_control_policy_tag_query_err
            kv
      | `Access_control_terrateam_config_update_match_parse_err m ->
          let kv = Snabela.Kv.(Map.of_list [ ("match", string m) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_TERRATEAM_CONFIG_UPDATE_MATCH_PARSE_ERR"
            Tmpl.repo_config_err_access_control_terrateam_config_update_match_parse_err
            kv
      | `Access_control_unlock_match_parse_err m ->
          let kv = Snabela.Kv.(Map.of_list [ ("match", string m) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_UNLOCK_MATCH_PARSE_ERR"
            Tmpl.repo_config_err_access_control_unlock_match_parse_err
            kv
      | `Apply_requirements_approved_all_of_match_parse_err m ->
          let kv = Snabela.Kv.(Map.of_list [ ("match", string m) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "APPLY_REQUIREMENTS_APPROVED_ALL_OF_MATCH_PARSE_ERR"
            Tmpl.repo_config_err_apply_requirements_approved_all_of_match_parse_err
            kv
      | `Apply_requirements_approved_any_of_match_parse_err m ->
          let kv = Snabela.Kv.(Map.of_list [ ("match", string m) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "APPLY_REQUIREMENTS_APPROVED_ANY_OF_MATCH_PARSE_ERR"
            Tmpl.repo_config_err_apply_requirements_approved_any_of_match_parse_err
            kv
      | `Apply_requirements_check_tag_query_err (q, err) ->
          let kv = Snabela.Kv.(Map.of_list [ ("query", string q); ("error", string err) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "APPLY_REQUIREMENTS_CHECK_TAG_QUERY_ERR"
            Tmpl.repo_config_err_apply_requirements_check_tag_query_err
            kv
      | `Depends_on_err (q, err) ->
          let kv = Snabela.Kv.(Map.of_list [ ("query", string q); ("error", string err) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "DRIFT_TAG_QUERY_ERR"
            Tmpl.repo_config_err_depends_on_err
            kv
      | `Drift_schedule_err s ->
          let kv = Snabela.Kv.(Map.of_list [ ("schedule", string s) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "DRIFT_SCHEDULE_ERR"
            Tmpl.repo_config_err_drift_schedule_err
            kv
      | `Drift_tag_query_err (q, err) ->
          let kv = Snabela.Kv.(Map.of_list [ ("query", string q); ("error", string err) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "DRIFT_TAG_QUERY_ERR"
            Tmpl.repo_config_err_drift_tag_query_err
            kv
      | `Glob_parse_err (s, err) ->
          let kv = Snabela.Kv.(Map.of_list [ ("glob", string s); ("error", string err) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "GLOB_PARSE_ERR"
            Tmpl.repo_config_err_glob_parse_err
            kv
      | `Hooks_unknown_run_on_err s ->
          let kv = Snabela.Kv.(Map.of_list [ ("run_on", string s) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "HOOKS_UNKNOWN_RUN_ON_ERR"
            Tmpl.repo_config_err_hooks_unknown_run_on_err
            kv
      | `Pattern_parse_err s ->
          let kv = Snabela.Kv.(Map.of_list [ ("pattern", string s) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "PATTERN_PARSE_ERR"
            Tmpl.repo_config_err_pattern_parse_err
            kv
      | `Unknown_lock_policy_err s ->
          let kv = Snabela.Kv.(Map.of_list [ ("lock_policy", string s) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "UNKNOWN_LOCK_POLICY_ERR"
            Tmpl.repo_config_err_unknown_lock_policy_err
            kv
      | `Unknown_plan_mode_err s -> assert false
      | `Workflows_apply_unknown_run_on_err s ->
          let kv = Snabela.Kv.(Map.of_list [ ("run_on", string s) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "WORKFLOWS_APPLY_UNKNOWN_RUN_ON_ERR"
            Tmpl.repo_config_err_workflows_apply_unknown_run_on_err
            kv
      | `Workflows_plan_unknown_run_on_err s ->
          let kv = Snabela.Kv.(Map.of_list [ ("run_on", string s) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "WORKFLOWS_PLAN_UNKNOWN_RUN_ON_ERR"
            Tmpl.repo_config_err_workflows_plan_unknown_run_on_err
            kv
      | `Workflows_tag_query_parse_err (q, err) ->
          let kv = Snabela.Kv.(Map.of_list [ ("query", string q); ("error", string err) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "WORKFLOWS_TAG_QUERY_PARSE_ERR"
            Tmpl.repo_config_err_workflows_tag_query_parse_err
            kv

    let publish_msg' ~request_id client user pull_request =
      let module Msg = Terrat_evaluator3.Msg in
      function
      | Msg.Access_control_denied (default_branch, `All_dirspaces denies) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("user", string user);
                  ("default_branch", string default_branch);
                  ( "denies",
                    list
                      (CCList.map
                         (fun Terrat_access_control.R.Deny.
                                {
                                  change_match =
                                    {
                                      Terrat_change_match3.Dirspace_config.dirspace =
                                        { Terrat_dirspace.dir; workspace };
                                      _;
                                    };
                                  policy;
                                } ->
                           Map.of_list
                             (CCList.flatten
                                [
                                  [ ("dir", string dir); ("workspace", string workspace) ];
                                  CCOption.map_or
                                    ~default:[]
                                    (fun policy ->
                                      [
                                        ( "match_list",
                                          list
                                            (CCList.map
                                               (fun s ->
                                                 Map.of_list
                                                   [
                                                     ( "item",
                                                       string
                                                         (Terrat_base_repo_config_v1.Access_control
                                                          .Match
                                                          .to_string
                                                            s) );
                                                   ])
                                               policy) );
                                      ])
                                    policy;
                                ]))
                         denies) );
                ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_ALL_DIRSPACES_DENIED"
            Tmpl.access_control_all_dirspaces_denied
            kv
      | Msg.Access_control_denied (default_branch, `Ci_config_update match_list) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("user", string user);
                  ("default_branch", string default_branch);
                  ( "match_list",
                    list
                      (CCList.map
                         (fun s ->
                           Map.of_list
                             [
                               ( "item",
                                 string
                                   (Terrat_base_repo_config_v1.Access_control.Match.to_string s) );
                             ])
                         match_list) );
                ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_CI_CONFIG_UPDATE_DENIED"
            Tmpl.access_control_ci_config_update_denied
            kv
      | Msg.Access_control_denied (default_branch, `Dirspaces denies) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("user", string user);
                  ("default_branch", string default_branch);
                  ( "denies",
                    list
                      (CCList.map
                         (fun Terrat_access_control.R.Deny.
                                {
                                  change_match =
                                    {
                                      Terrat_change_match3.Dirspace_config.dirspace =
                                        { Terrat_dirspace.dir; workspace };
                                      _;
                                    };
                                  policy;
                                } ->
                           Map.of_list
                             (CCList.flatten
                                [
                                  [ ("dir", string dir); ("workspace", string workspace) ];
                                  CCOption.map_or
                                    ~default:[]
                                    (fun policy ->
                                      [
                                        ( "match_list",
                                          list
                                            (CCList.map
                                               (fun s ->
                                                 Map.of_list
                                                   [
                                                     ( "item",
                                                       string
                                                         (Terrat_base_repo_config_v1.Access_control
                                                          .Match
                                                          .to_string
                                                            s) );
                                                   ])
                                               policy) );
                                      ])
                                    policy;
                                ]))
                         denies) );
                ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_DIRSPACES_DENIED"
            Tmpl.access_control_dirspaces_denied
            kv
      | Msg.Access_control_denied (default_branch, `Files (fname, match_list)) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("user", string user);
                  ("default_branch", string default_branch);
                  ("filename", string fname);
                  ( "match_list",
                    list
                      (CCList.map
                         (fun s ->
                           Map.of_list
                             [
                               ( "item",
                                 string
                                   (Terrat_base_repo_config_v1.Access_control.Match.to_string s) );
                             ])
                         match_list) );
                ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_FILES"
            Tmpl.access_control_files_denied
            kv
      | Msg.Access_control_denied (default_branch, `Terrateam_config_update match_list) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("user", string user);
                  ("default_branch", string default_branch);
                  ( "match_list",
                    list
                      (CCList.map
                         (fun s ->
                           Map.of_list
                             [
                               ( "item",
                                 string
                                   (Terrat_base_repo_config_v1.Access_control.Match.to_string s) );
                             ])
                         match_list) );
                ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_TERRATEAM_CONFIG_UPDATE_DENIED"
            Tmpl.access_control_terrateam_config_update_denied
            kv
      | Msg.Access_control_denied (default_branch, `Lookup_err) ->
          let kv =
            Snabela.Kv.(
              Map.of_list [ ("user", string user); ("default_branch", string default_branch) ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_LOOKUP_ERR"
            Tmpl.access_control_lookup_err
            kv
      | Msg.Access_control_denied (default_branch, `Unlock match_list) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("user", string user);
                  ("default_branch", string default_branch);
                  ( "match_list",
                    list
                      (CCList.map
                         (fun s ->
                           Map.of_list
                             [
                               ( "item",
                                 string
                                   (Terrat_base_repo_config_v1.Access_control.Match.to_string s) );
                             ])
                         match_list) );
                ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCESS_CONTROL_UNLOCK_DENIED"
            Tmpl.access_control_unlock_denied
            kv
      | Msg.Account_expired ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "ACCOUNT_EXPIRED"
            Tmpl.account_expired_err
            kv
      | Msg.Apply_no_matching_dirspaces ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "APPLY_NO_MATCHING_DIRSPACES"
            Tmpl.apply_no_matching_dirspaces
            kv
      | Msg.Apply_requirements_config_err (`Tag_query_error (query, err)) ->
          let kv = Snabela.Kv.(Map.of_list [ ("query", string query); ("error", string err) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "APPLY_REQUIREMENTS_CONFIG_ERR_TAG_QUERY"
            Tmpl.apply_requirements_config_err_tag_query
            kv
      | Msg.Apply_requirements_config_err (`Invalid_query query) ->
          let kv = Snabela.Kv.(Map.of_list [ ("query", string query) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "APPLY_REQUIREMENTS_CONFIG_ERR_INVALID_QUERY"
            Tmpl.apply_requirements_config_err_invalid_query
            kv
      | Msg.Apply_requirements_validation_err ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "APPLY_REQUIREMENTS_VALIDATION_ERR"
            Tmpl.apply_requirements_validation_err
            kv
      | Msg.Autoapply_running ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "AUTO_APPLY_RUNNING"
            Tmpl.auto_apply_running
            kv
      | Msg.Bad_custom_branch_tag_pattern (tag, pat) ->
          let kv = Snabela.Kv.(Map.of_list [ ("tag", string tag); ("pattern", string pat) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "BAD_CUSTOM_BRANCH_TAG_PATTERN"
            Tmpl.bad_custom_branch_tag_pattern
            kv
      | Msg.Bad_glob s ->
          let kv = Snabela.Kv.(Map.of_list [ ("glob", string s) ]) in
          apply_template_and_publish ~request_id client pull_request "BAD_GLOB" Tmpl.bad_glob kv
      | Msg.Build_config_err err -> repo_config_err ~request_id ~client ~pull_request ~title:"" err
      | Msg.Build_config_failure err ->
          repo_config_failure ~request_id ~client ~pull_request ~title:"built" err
      | Msg.Conflicting_work_manifests wms ->
          let module Wm = Terrat_work_manifest3 in
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ( "work_manifests",
                    list
                      (CCList.map
                         (fun { Wm.created_at; steps; state; target; _ } ->
                           let id, is_pr =
                             match target with
                             | Terrat_evaluator3.Target.Pr pr ->
                                 (CCInt.to_string (Pull_request.id pr), true)
                             | Terrat_evaluator3.Target.Drift _ -> ("drift", false)
                           in
                           Map.of_list
                             [
                               ("id", string id);
                               ("is_pr", bool is_pr);
                               ( "run_type",
                                 string
                                   (CCString.capitalize_ascii
                                      (Wm.Step.to_string
                                         (CCOption.get_exn_or
                                            "Conflicting_work_manifests"
                                            (CCList.last_opt steps)))) );
                               ( "state",
                                 string (CCString.capitalize_ascii (Wm.State.to_string state)) );
                               ( "created_at",
                                 string
                                   (let Unix.{ tm_year; tm_mon; tm_mday; tm_hour; tm_min; _ } =
                                      Unix.gmtime (ISO8601.Permissive.datetime created_at)
                                    in
                                    Printf.sprintf
                                      "%d-%d-%d %d:%d"
                                      (1900 + tm_year)
                                      (tm_mon + 1)
                                      tm_mday
                                      tm_hour
                                      tm_min) );
                             ])
                         wms) );
                ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "CONFLICTING_WORK_MANIFESTS"
            Tmpl.conflicting_work_manifests
            kv
      | Msg.Depends_on_cycle cycle ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ( "cycle",
                    list
                      (CCList.map
                         (fun { Terrat_dirspace.dir; workspace } ->
                           Map.of_list [ ("dir", string dir); ("workspace", string workspace) ])
                         cycle) );
                ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "DEPENDS_ON_CYCLE"
            Tmpl.depends_on_cycle
            kv
      | Msg.Dest_branch_no_match pull_request ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ( "source_branch",
                    string (CCString.lowercase_ascii pull_request.Pull_request.branch_name) );
                  ( "dest_branch",
                    string (CCString.lowercase_ascii pull_request.Pull_request.base_branch_name) );
                ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "DEST_BRANCH_NO_MATCH"
            Tmpl.base_branch_not_default_branch
            kv
      | Msg.Dirspaces_owned_by_other_pull_request prs ->
          let unique_pull_request_ids =
            prs
            |> CCList.map (fun (_, Pull_request.{ id; _ }) -> id)
            |> CCList.sort_uniq ~cmp:CCInt.compare
          in
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ( "dirspaces",
                    list
                      (CCList.map
                         (fun (Terrat_change.Dirspace.{ dir; workspace }, Pull_request.{ id; _ }) ->
                           Map.of_list
                             [
                               ("dir", string dir);
                               ("workspace", string workspace);
                               ("pull_request_id", int id);
                             ])
                         prs) );
                  ( "unique_pull_request_ids",
                    list
                      (CCList.map
                         (fun id -> Map.of_list [ ("id", int id) ])
                         unique_pull_request_ids) );
                ])
          in
          CCList.iter
            (fun (Terrat_change.Dirspace.{ dir; workspace }, Pull_request.{ id; _ }) ->
              Logs.info (fun m ->
                  m
                    "GITHUB_EVALUATOR : %s : DIRSPACES_OWNED_BY_OTHER_PR : dir=%s : workspace=%s : \
                     pull_number=%d"
                    request_id
                    dir
                    workspace
                    id))
            prs;
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "DIRSPACES_OWNED_BY_OTHER_PRS"
            Tmpl.dirspaces_owned_by_other_pull_requests
            kv
      | Msg.Help ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "HELP"
            Tmpl.terrateam_comment_help
            kv
      | Msg.Index_complete (success, failures) ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ("success", bool success);
                  ( "failures",
                    list
                      (CCList.map
                         (fun (path, lnum, msg) ->
                           Map.of_list
                             (CCList.flatten
                                [
                                  [ ("path", string path); ("failure", string msg) ];
                                  CCOption.map_or
                                    ~default:[]
                                    (fun lnum -> [ ("line", int lnum) ])
                                    lnum;
                                ]))
                         failures) );
                ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "INDEX_COMPLETE"
            Tmpl.index_complete
            kv
      | Msg.Invalid_unlock_id unlock_id ->
          let kv = Snabela.Kv.(Map.of_list [ ("unlock_id", string unlock_id) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "INVALID_UNLOCK_ID"
            Tmpl.invalid_lock_id
            kv
      | Msg.Maybe_stale_work_manifests wms ->
          let module Wm = Terrat_work_manifest3 in
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ( "work_manifests",
                    list
                      (CCList.map
                         (fun Wm.{ created_at; steps; state; target; _ } ->
                           let id, is_pr =
                             match target with
                             | Terrat_evaluator3.Target.Pr pr ->
                                 (CCInt.to_string (Pull_request.id pr), true)
                             | Terrat_evaluator3.Target.Drift _ -> ("drift", false)
                           in
                           Map.of_list
                             [
                               ("id", string id);
                               ("is_pr", bool is_pr);
                               ( "run_type",
                                 string
                                   (CCString.capitalize_ascii
                                      (Wm.Step.to_string
                                         (CCOption.get_exn_or
                                            "Maybe_stale_work_manifests"
                                            (CCList.last_opt steps)))) );
                               ( "state",
                                 string (CCString.capitalize_ascii (Wm.State.to_string state)) );
                               ( "created_at",
                                 string
                                   (let Unix.{ tm_year; tm_mon; tm_mday; tm_hour; tm_min; _ } =
                                      Unix.gmtime (ISO8601.Permissive.datetime created_at)
                                    in
                                    Printf.sprintf
                                      "%d-%d-%d %d:%d"
                                      (1900 + tm_year)
                                      (tm_mon + 1)
                                      tm_mday
                                      tm_hour
                                      tm_min) );
                             ])
                         wms) );
                ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "MAYBE_STALE_WORK_MANIFESTS"
            Tmpl.maybe_stale_work_manifests
            kv
      | Msg.Mismatched_refs ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "MISMATCHED_REFS"
            Tmpl.mismatched_refs
            kv
      | Msg.Missing_plans dirspaces ->
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ( "dirspaces",
                    list
                      (CCList.map
                         (fun Terrat_change.Dirspace.{ dir; workspace } ->
                           Map.of_list [ ("dir", string dir); ("workspace", string workspace) ])
                         dirspaces) );
                ])
          in
          CCList.iter
            (fun Terrat_change.Dirspace.{ dir; workspace } ->
              Logs.info (fun m ->
                  m "GITHUB_EVALUATOR : %s : MISSING_PLANS : %s : %s" request_id dir workspace))
            dirspaces;
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "MISSING_PLANS"
            Tmpl.missing_plans
            kv
      | Msg.Plan_no_matching_dirspaces ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "PLAN_NO_MATCHING_DIRSPACES"
            Tmpl.plan_no_matching_dirspaces
            kv
      | Msg.Pull_request_not_appliable (_, apply_requirements) ->
          let module Dc = Terrat_change_match3.Dirspace_config in
          let module Ds = Terrat_dirspace in
          let module Ar = Apply_requirements.Result in
          let kv =
            Snabela.Kv.(
              Map.of_list
                [
                  ( "checks",
                    list
                      (CCList.map
                         (fun ar ->
                           Map.of_list
                             [
                               ("dir", string ar.Ar.match_.Dc.dirspace.Ds.dir);
                               ("workspace", string ar.Ar.match_.Dc.dirspace.Ds.workspace);
                               ("passed", bool ar.Ar.passed);
                               ("approved_enabled", bool (CCOption.is_some ar.Ar.approved));
                               ( "approved_check",
                                 bool (CCOption.get_or ~default:false ar.Ar.approved) );
                               ( "merge_conflicts_enabled",
                                 bool (CCOption.is_some ar.Ar.merge_conflicts) );
                               ( "merge_conflicts_check",
                                 bool (CCOption.get_or ~default:false ar.Ar.merge_conflicts) );
                               ("status_checks_enabled", bool (CCOption.is_some ar.Ar.status_checks));
                               ( "status_checks_check",
                                 bool (CCOption.get_or ~default:false ar.Ar.status_checks) );
                               ( "status_checks_failed",
                                 list
                                   (CCList.map
                                      (fun Terrat_commit_check.{ title; _ } ->
                                        Map.of_list [ ("title", string title) ])
                                      ar.Ar.status_checks_failed) );
                             ])
                         (CCList.sort
                            (fun { Ar.passed = passed1; _ } { Ar.passed = passed2; _ } ->
                              Bool.compare passed1 passed2)
                            apply_requirements)) );
                ])
          in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "PULL_REQUEST_NOT_APPLIABLE"
            Tmpl.pull_request_not_appliable
            kv
      | Msg.Pull_request_not_mergeable ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "PULL_REQUEST_NOT_MERGEABLE"
            Tmpl.pull_request_not_mergeable
            kv
      | Msg.Repo_config (provenance, repo_config) -> (
          let ret =
            let open Abbs_future_combinators.Infix_result_monad in
            let repo_config_json =
              Terrat_repo_config.Version_1.to_yojson
                (Terrat_base_repo_config_v1.to_version_1 repo_config)
            in
            Jsonu.to_yaml_string repo_config_json
            >>= fun repo_config_yaml ->
            let kv =
              Snabela.Kv.(
                Map.of_list
                  [
                    ("repo_config", string repo_config_yaml);
                    ( "provenance",
                      list (CCList.map (fun src -> Map.of_list [ ("src", string src) ]) provenance)
                    );
                  ])
            in
            Abb.Future.return (Ok kv)
          in
          let open Abb.Future.Infix_monad in
          ret
          >>= function
          | Ok kv ->
              apply_template_and_publish
                ~request_id
                client
                pull_request
                "REPO_CONFIG"
                Tmpl.repo_config
                kv
          | Error (#Jsonu.to_yaml_string_err as err) ->
              Logs.err (fun m ->
                  m
                    "GITHUB_EVALUATOR : %s : TO_YAML : %a"
                    request_id
                    Jsonu.pp_to_yaml_string_err
                    err);
              Abb.Future.return (Error `Error))
      | Msg.Repo_config_err err -> repo_config_err ~request_id ~client ~pull_request ~title:"" err
      | Msg.Repo_config_failure err ->
          repo_config_failure ~request_id ~client ~pull_request ~title:"Terrateam repository" err
      | Msg.Repo_config_parse_failure (fname, err) ->
          let kv = Snabela.Kv.(Map.of_list [ ("fname", string fname); ("msg", string err) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "REPO_CONFIG_PARSE_FAILURE"
            Tmpl.repo_config_parse_failure
            kv
      | Msg.Run_work_manifest_err `Failed_to_start ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "RUN_WORK_MANIFEST_ERR_FAILED_TO_START"
            Tmpl.failed_to_start_workflow
            kv
      | Msg.Run_work_manifest_err `Missing_workflow ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "RUN_WORK_MANIFEST_ERR_MISSING_WORKFLOW"
            Tmpl.failed_to_find_workflow
            kv
      | Msg.Tag_query_err (`Tag_query_error (s, err)) ->
          let kv = Snabela.Kv.(Map.of_list [ ("query", string s); ("err", string err) ]) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "TAG_QUERY_ERR"
            Tmpl.tag_query_error
            kv
      | Msg.Tf_op_result { is_layered_run; remaining_layers; result; work_manifest } -> (
          let open Abb.Future.Infix_monad in
          Result_publisher.iterate_comment_posts
            request_id
            client
            is_layered_run
            remaining_layers
            result
            pull_request
            work_manifest
          >>= function
          | Ok () -> Abb.Future.return (Ok ())
          | Error _ -> Abb.Future.return (Error `Error))
      | Msg.Unexpected_temporary_err ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "UNEXPECTED_TEMPORARY_ERR"
            Tmpl.unexpected_temporary_err
            kv
      | Msg.Unlock_success ->
          let kv = Snabela.Kv.(Map.of_list []) in
          apply_template_and_publish
            ~request_id
            client
            pull_request
            "UNLOCK_SUCCESS"
            Tmpl.unlock_success
            kv

    let publish_msg ~request_id client user pull_request msg =
      publish_msg' ~request_id client user pull_request msg

    let diff_of_github_diff =
      CCList.map
        Githubc2_components.Diff_entry.(
          function
          | { primary = { Primary.filename; status = "added" | "copied"; _ }; _ } ->
              Terrat_change.Diff.Add { filename }
          | { primary = { Primary.filename; status = "removed"; _ }; _ } ->
              Terrat_change.Diff.Remove { filename }
          | { primary = { Primary.filename; status = "modified" | "changed" | "unchanged"; _ }; _ }
            -> Terrat_change.Diff.Change { filename }
          | {
              primary =
                {
                  Primary.filename;
                  status = "renamed";
                  previous_filename = Some previous_filename;
                  _;
                };
              _;
            } -> Terrat_change.Diff.Move { filename; previous_filename }
          | _ -> failwith "nyi1")

    let fetch_diff ~client ~owner ~repo pull_number =
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.fetch_pull_request_files ~owner ~repo ~pull_number client.Client.client
      >>= fun github_diff ->
      let diff = diff_of_github_diff github_diff in
      Abb.Future.return (Ok diff)

    let fetch_pull_request' request_id account client repo pull_request_id =
      let owner = repo.Repo.owner in
      let repo_name = repo.Repo.name in
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun resp diff -> (resp, diff))
        <$> Terrat_github.fetch_pull_request
              ~owner
              ~repo:repo_name
              ~pull_number:pull_request_id
              client.Client.client
        <*> fetch_diff ~client ~owner ~repo:repo_name pull_request_id)
      >>= fun (resp, diff) ->
      let module Ghc_comp = Githubc2_components in
      let module Pr = Ghc_comp.Pull_request in
      let module Head = Pr.Primary.Head in
      let module Base = Pr.Primary.Base in
      let module User = Ghc_comp.Simple_user in
      match Openapi.Response.value resp with
      | `OK
          {
            Ghc_comp.Pull_request.primary =
              {
                Ghc_comp.Pull_request.Primary.head;
                base;
                state;
                merged;
                merged_at;
                merge_commit_sha;
                mergeable_state;
                mergeable;
                draft;
                title;
                user = User.{ primary = Primary.{ login; _ }; _ };
                _;
              };
            _;
          } ->
          let base_branch_name = Base.(base.primary.Primary.ref_) in
          let base_sha = Base.(base.primary.Primary.sha) in
          let head_sha = Head.(head.primary.Primary.sha) in
          let branch_name = Head.(head.primary.Primary.ref_) in
          let draft = CCOption.get_or ~default:false draft in
          Prmths.Counter.inc_one (Metrics.pull_request_mergeable_state_count mergeable_state);
          Logs.info (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGEABLE : merged=%s : mergeable_state=%s : \
                 merge_commit_sha=%s"
                request_id
                (Bool.to_string merged)
                mergeable_state
                (CCOption.get_or ~default:"" merge_commit_sha));
          Abb.Future.return
            (Ok
               ( mergeable_state,
                 {
                   Pull_request.base_branch_name;
                   base_ref = base_sha;
                   branch_name;
                   branch_ref = head_sha;
                   id = pull_request_id;
                   state =
                     (match (merge_commit_sha, state, merged, merged_at) with
                     | Some _, "open", _, _ ->
                         Terrat_pull_request.State.(Open Open_status.Mergeable)
                     | None, "open", _, _ ->
                         Terrat_pull_request.State.(Open Open_status.Merge_conflict)
                     | Some merge_commit_sha, "closed", true, Some merged_at ->
                         Terrat_pull_request.State.(
                           Merged Merged.{ merged_hash = merge_commit_sha; merged_at })
                     | _, "closed", false, _ -> Terrat_pull_request.State.Closed
                     | _, _, _, _ -> assert false);
                   title = Some title;
                   user = Some login;
                   repo;
                   value =
                     {
                       Pull_request.checks =
                         merged
                         || CCList.mem
                              ~eq:CCString.equal
                              mergeable_state
                              [ "clean"; "unstable"; "has_hooks" ];
                       diff;
                       is_draft_pr = draft;
                       mergeable;
                       provisional_merge_ref = merge_commit_sha;
                     };
                 } ))
      | (`Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _) as err ->
          Abb.Future.return (Error err)

    let fetch_pull_request ~request_id account client repo pull_request_id =
      let open Abb.Future.Infix_monad in
      let fetch () = fetch_pull_request' request_id account client repo pull_request_id in
      let f () =
        fetch ()
        >>= function
        | Ok ret -> Abb.Future.return (Ok ret)
        | Error (`Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _)
          as err -> Abb.Future.return err
        | Error `Error ->
            Prmths.Counter.inc_one Metrics.github_errors_total;
            Logs.err (fun m ->
                m "GITHUB_EVALUATOR : %s : ERROR : repo=%s : ERROR" request_id (Repo.to_string repo));
            Abb.Future.return (Error `Error)
        | Error (#Terrat_github.compare_commits_err as err) ->
            Prmths.Counter.inc_one Metrics.github_errors_total;
            Logs.err (fun m ->
                m
                  "GITHUB_EVALUATOR : %s : ERROR : repo=%s : %a"
                  request_id
                  (Repo.to_string repo)
                  Terrat_github.pp_compare_commits_err
                  err);
            Abb.Future.return (Error `Error)
      in
      Abbs_future_combinators.retry
        ~f
        ~while_:
          (Abbs_future_combinators.finite_tries fetch_pull_request_tries (function
              | Error _
              | Ok ("unknown", { Pull_request.state = Terrat_pull_request.State.Open _; _ }) -> true
              | Ok _ -> false))
        ~betwixt:
          (Abbs_future_combinators.series ~start:2.0 ~step:(( *. ) 1.5) (fun n _ ->
               Prmths.Counter.inc_one Metrics.fetch_pull_request_errors_total;
               Abb.Sys.sleep (CCFloat.min n 8.0)))
      >>= function
      | Ok (_, ret) -> Abb.Future.return (Ok ret)
      | Error (`Not_found _)
      | Error (`Internal_server_error _)
      | Error `Not_modified
      | Error (`Service_unavailable _)
      | Error `Error -> Abb.Future.return (Error `Error)

    let react_to_comment ~request_id client repo comment_id =
      let open Abb.Future.Infix_monad in
      Terrat_github.react_to_comment
        ~owner:(Repo.owner repo)
        ~repo:(Repo.name repo)
        ~comment_id
        client.Client.client
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Terrat_github.publish_reaction_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : REACT_TO_COMMENT : %a"
                request_id
                Terrat_github.pp_publish_reaction_err
                err);
          Abb.Future.return (Error `Error)

    let update_work_manifest_state ~request_id db work_manifest_id state =
      let module Wm = Terrat_work_manifest3 in
      let sql =
        match state with
        | Wm.State.Running -> Sql.update_work_manifest_state_running
        | Wm.State.Completed -> Sql.update_work_manifest_state_completed
        | Wm.State.Aborted -> Sql.update_work_manifest_state_aborted
        | Wm.State.Queued -> assert false
      in
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.execute db (sql ()) work_manifest_id
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let update_work_manifest_run_id ~request_id db work_manifest_id run_id =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.execute
        db
        (Sql.update_work_manifest_run_id ())
        work_manifest_id
        (Some run_id)
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let update_work_manifest_changes ~request_id db work_manifest_id changes =
      let module Tc = Terrat_change in
      let module Dsf = Tc.Dirspaceflow in
      let module Ds = Tc.Dirspace in
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.List_result.iter
        ~f:(fun changes ->
          Pgsql_io.Prepared_stmt.execute
            db
            (Sql.insert_work_manifest_dirspaceflow ())
            (CCList.replicate (CCList.length changes) work_manifest_id)
            (CCList.map (fun { Dsf.dirspace = { Ds.dir; _ }; _ } -> dir) changes)
            (CCList.map (fun { Dsf.dirspace = { Ds.workspace; _ }; _ } -> workspace) changes)
            (CCList.map (fun { Dsf.workflow; _ } -> workflow) changes))
        (CCList.chunks 500 changes)
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let update_work_manifest_denied_dirspaces ~request_id db work_manifest_id denied_dirspaces =
      let module Ch = Terrat_change in
      let module Wm = Terrat_work_manifest3 in
      let open Abb.Future.Infix_monad in
      let module Policy = struct
        type t = Terrat_base_repo_config_v1.Access_control.Match_list.t [@@deriving yojson]
      end in
      Abbs_future_combinators.List_result.iter
        ~f:(fun denied_dirspaces ->
          Pgsql_io.Prepared_stmt.execute
            db
            Sql.insert_work_manifest_access_control_denied_dirspace
            (CCList.map
               (fun { Wm.Deny.dirspace = { Ch.Dirspace.dir; _ }; _ } -> dir)
               denied_dirspaces)
            (CCList.map
               (fun { Wm.Deny.dirspace = { Ch.Dirspace.workspace; _ }; _ } -> workspace)
               denied_dirspaces)
            (CCList.map
               (fun { Wm.Deny.policy; _ } ->
                 (* This has a very awkward JSON conversion because we are
                    performing this insert by passing in a bunch of arrays
                    of values.  However policy is already an array and SQL
                    does not support multidimensional arrays where the
                    inner arrays can have different dimensions.  So we need
                    to convert the policy to a string so that we can pass
                    in an array of strings, and it needs to be in a format
                    postgresql can turn back into an array.  So we use JSON
                    as the intermediate representation. *)
                 CCOption.map (fun policy -> Yojson.Safe.to_string (Policy.to_yojson policy)) policy)
               denied_dirspaces)
            (CCList.replicate (CCList.length denied_dirspaces) work_manifest_id))
        (CCList.chunks 500 denied_dirspaces)
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let update_work_manifest_steps ~request_id db work_manifest_id steps =
      let open Abb.Future.Infix_monad in
      let run_type =
        CCOption.map_or ~default:"" Terrat_work_manifest3.Step.to_string (CCList.last_opt steps)
      in
      Pgsql_io.Prepared_stmt.execute db Sql.update_run_type work_manifest_id run_type
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let create_work_manifest ~request_id db work_manifest =
      let run =
        let module Wm = Terrat_work_manifest3 in
        let module Tc = Terrat_change in
        let module Dsf = Tc.Dirspaceflow in
        let module Ds = Tc.Dirspace in
        let open Abbs_future_combinators.Infix_result_monad in
        let dirspaces_json =
          `List
            (CCList.map
               (fun dsf ->
                 let ds = Dsf.to_dirspace dsf in
                 `Assoc [ ("dir", `String ds.Ds.dir); ("workspace", `String ds.Ds.workspace) ])
               work_manifest.Wm.changes)
        in
        let dirspaces = Yojson.Safe.to_string dirspaces_json in
        let pull_number_opt =
          match work_manifest.Wm.target with
          | Terrat_evaluator3.Target.Pr { Pull_request.id; _ } -> Some id
          | Terrat_evaluator3.Target.Drift _ -> None
        in
        let repo_id =
          match work_manifest.Wm.target with
          | Terrat_evaluator3.Target.Pr { Pull_request.repo; _ } -> repo.Repo.id
          | Terrat_evaluator3.Target.Drift { repo; _ } -> repo.Repo.id
        in
        let run_kind =
          match work_manifest.Wm.target with
          | Terrat_evaluator3.Target.Pr _ -> "pr"
          | Terrat_evaluator3.Target.Drift _ -> "drift"
        in
        let run_type =
          CCOption.map_or
            ~default:""
            Terrat_work_manifest3.Step.to_string
            (CCList.last_opt work_manifest.Wm.steps)
        in
        let user =
          match work_manifest.Wm.initiator with
          | Wm.Initiator.User user -> Some user
          | Wm.Initiator.System -> None
        in
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.insert_work_manifest ())
          ~f:(fun id state created_at -> (id, state, created_at))
          work_manifest.Wm.base_ref
          (CCOption.map CCInt64.of_int pull_number_opt)
          (CCInt64.of_int repo_id)
          run_type
          work_manifest.Wm.branch_ref
          (Terrat_tag_query.to_string work_manifest.Wm.tag_query)
          user
          dirspaces
          run_kind
          work_manifest.Wm.environment
        >>= function
        | [] -> assert false
        | (id, state, created_at) :: _ -> (
            update_work_manifest_changes ~request_id db id work_manifest.Wm.changes
            >>= fun () ->
            update_work_manifest_denied_dirspaces
              ~request_id
              db
              id
              work_manifest.Wm.denied_dirspaces
            >>= fun () ->
            let work_manifest = { work_manifest with Wm.id; state; created_at; run_id = None } in
            match work_manifest.Wm.target with
            | Terrat_evaluator3.Target.Pr _ -> Abb.Future.return (Ok work_manifest)
            | Terrat_evaluator3.Target.Drift { repo; branch } ->
                Pgsql_io.Prepared_stmt.execute db (Sql.insert_drift_work_manifest ()) id branch
                >>= fun () -> Abb.Future.return (Ok work_manifest))
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)
      | Error `Error -> Abb.Future.return (Error `Error)

    let make_commit_check = Terratc.Github.Commit_check.make_commit_check

    let create_commit_checks ~request_id client repo ref_ checks =
      let open Abb.Future.Infix_monad in
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : CREATE_COMMIT_CHECKS : num=%d"
            request_id
            (CCList.length checks));
      Terrat_github_commit_check.create
        ~owner:(Repo.owner repo)
        ~repo:(Repo.name repo)
        ~ref_
        ~checks
        client.Client.client
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Githubc2_abb.call_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Githubc2_abb.pp_call_err err);
          Abb.Future.return (Error `Error)

    let fetch_commit_checks ~request_id client repo ref_ =
      let open Abb.Future.Infix_monad in
      let owner = Repo.owner repo in
      let repo = Repo.name repo in
      Abbs_time_it.run
        (fun time ->
          Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : LIST_COMMIT_CHECKS : %f" request_id time))
        (fun () ->
          Terrat_github_commit_check.list ~log_id:request_id ~owner ~repo ~ref_ client.Client.client)
      >>= function
      | Ok _ as res -> Abb.Future.return res
      | Error (#Terrat_github_commit_check.list_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : FETCH_COMMIT_CHECKS : %a"
                request_id
                Terrat_github_commit_check.pp_list_err
                err);
          Abb.Future.return (Error `Error)

    let query_next_pending_work_manifest ~request_id db =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_io.Prepared_stmt.fetch db ~f:CCFun.id Sql.select_next_work_manifest
        >>= function
        | [] -> Abb.Future.return (Ok None)
        | [ id ] ->
            Abbs_time_it.run
              (fun time ->
                Logs.info (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : QUERY_WORK_MANIFEST : id=%a : time=%f"
                      request_id
                      Uuidm.pp
                      id
                      time))
              (fun () ->
                query_work_manifest ~request_id db id
                >>= function
                | Some wm ->
                    let module Wm = Terrat_work_manifest3 in
                    assert (wm.Wm.state = Wm.State.Queued);
                    Abb.Future.return (Ok (Some wm))
                | None -> Abb.Future.return (Ok None))
        | _ :: _ -> assert false
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_pool.pp_err err);
          Abb.Future.return (Error `Error)
      | Error `Error -> Abb.Future.return (Error `Error)

    let run_work_manifest ~request_id config client work_manifest =
      let module Wm = Terrat_work_manifest3 in
      let get_repo = function
        | { Wm.target = Terrat_evaluator3.Target.Pr pr; _ } -> Pull_request.repo pr
        | { Wm.target = Terrat_evaluator3.Target.Drift { repo; _ }; _ } -> repo
      in
      let get_branch = function
        | { Wm.target = Terrat_evaluator3.Target.Pr pr; _ } -> (
            match Pull_request.state pr with
            | Pull_request.State.(Open _ | Closed) -> Pull_request.branch_name pr
            | Pull_request.State.Merged _ -> Pull_request.base_branch_name pr)
        | { Wm.target = Terrat_evaluator3.Target.Drift { branch; _ }; _ } -> branch
      in
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        let repo = get_repo work_manifest in
        let branch = get_branch work_manifest in
        Terrat_github.load_workflow ~owner:repo.Repo.owner ~repo:repo.Repo.name client.Client.client
        >>= function
        | Some workflow_id -> (
            let open Abb.Future.Infix_monad in
            Terrat_github.call
              client.Client.client
              Githubc2_actions.Create_workflow_dispatch.(
                make
                  ~body:
                    Request_body.
                      {
                        primary =
                          Primary.
                            {
                              ref_ = branch;
                              inputs =
                                Some
                                  Inputs.
                                    {
                                      primary = Json_schema.Empty_obj.t;
                                      additional =
                                        Json_schema.String_map.of_list
                                          ([
                                             ( "work-token",
                                               `String (Uuidm.to_string work_manifest.Wm.id) );
                                             ( "api-base-url",
                                               `String (Terrat_config.api_base config ^ "/github")
                                             );
                                           ]
                                          @
                                          match work_manifest.Wm.environment with
                                          | Some env -> [ ("environment", `String env) ]
                                          | None -> []);
                                    };
                            };
                        additional = Json_schema.String_map.empty;
                      }
                  Parameters.(
                    make
                      ~owner:repo.Repo.owner
                      ~repo:repo.Repo.name
                      ~workflow_id:(Workflow_id.V0 workflow_id)))
            >>= function
            | Ok _ -> (
                match CCList.last_opt work_manifest.Wm.steps with
                | Some step ->
                    Terrat_telemetry.send
                      (Terrat_config.telemetry config)
                      (make_run_telemetry config step repo)
                    >>= fun () -> Abb.Future.return (Ok ())
                | None -> Abb.Future.return (Ok ()))
            | Error (`Missing_response resp as err)
              when CCString.mem ~sub:"No ref found for:" (Openapi.Response.value resp) ->
                (* If the ref has been deleted while we are looking up the
                   workflow, just ignore and move on. *)
                Logs.err (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : ERROR : REF_NOT_FOUND : %s : %s : %s : %a"
                      request_id
                      (Repo.owner repo)
                      (Repo.name repo)
                      branch
                      Githubc2_abb.pp_call_err
                      err);
                Abb.Future.return (Ok ())
            | Error (#Githubc2_abb.call_err as err) ->
                Logs.err (fun m ->
                    m
                      "GITHUB_EVALUATOR : %s : FAILED_TO_START : %s : %s : %s : %a"
                      request_id
                      (Repo.owner repo)
                      (Repo.name repo)
                      branch
                      Githubc2_abb.pp_call_err
                      err);
                Abb.Future.return (Error `Failed_to_start))
        | None -> Abb.Future.return (Error `Missing_workflow)
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)
      | Error (#Terrat_github.publish_comment_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s: ERROR : %a"
                request_id
                Terrat_github.pp_publish_comment_err
                err);
          Abb.Future.return (Error `Error)
      | Error (#Terrat_github.get_installation_access_token_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s: ERROR : %a"
                request_id
                Terrat_github.pp_get_installation_access_token_err
                err);
          Abb.Future.return (Error `Error)
      | Error ((`Missing_workflow | `Failed_to_start) as err) -> Abb.Future.return (Error err)
      | Error `Error -> Abb.Future.return (Error `Error)

    let store_flow_state ~request_id db work_manifest_id data =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.execute db (Sql.upsert_flow_state ()) work_manifest_id data
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let query_flow_state ~request_id db work_manifest_id =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.fetch db (Sql.select_flow_state ()) ~f:CCFun.id work_manifest_id
      >>= function
      | Ok (data :: _) -> Abb.Future.return (Ok (Some data))
      | Ok [] -> Abb.Future.return (Ok None)
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let cleanup_flow_states ~request_id db =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.execute db (Sql.delete_stale_flow_states ())
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let delete_flow_state ~request_id db work_manifest_id =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.execute db (Sql.delete_flow_state ()) work_manifest_id
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let unlock' db repo = function
      | Terrat_evaluator3.Unlock_id.Pull_request pull_request_id ->
          Pgsql_io.Prepared_stmt.execute
            db
            (Sql.insert_pull_request_unlock ())
            (CCInt64.of_int (Repo.id repo))
            (CCInt64.of_int pull_request_id)
      | Terrat_evaluator3.Unlock_id.Drift ->
          Pgsql_io.Prepared_stmt.execute
            db
            (Sql.insert_drift_unlock ())
            (CCInt64.of_int (Repo.id repo))

    let unlock ~request_id db repo unlock_id =
      let open Abb.Future.Infix_monad in
      unlock' db repo unlock_id
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_pool.pp_err err);
          Abb.Future.return (Error `Error)

    let query_pull_request_out_of_change_applies ~request_id db pull_request =
      let run =
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_out_of_diff_applies
          ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
          (CCInt64.of_int pull_request.Pull_request.repo.Repo.id)
          (CCInt64.of_int pull_request.Pull_request.id)
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok dirspaces -> Abb.Future.return (Ok dirspaces)
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let query_applied_dirspaces ~request_id db pull_request =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_dirspace_applies_for_pull_request
        ~f:(fun dir workspace -> { Terrat_dirspace.dir; workspace })
        (CCInt64.of_int pull_request.Pull_request.repo.Repo.id)
        (CCInt64.of_int pull_request.Pull_request.id)
      >>= function
      | Ok dirspaces -> Abb.Future.return (Ok dirspaces)
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let query_dirspaces_without_valid_plans ~request_id db pull_request dirspaces =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.fetch
        db
        ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
        Sql.select_dirspaces_without_valid_plans
        (CCInt64.of_int pull_request.Pull_request.repo.Repo.id)
        (CCInt64.of_int pull_request.Pull_request.id)
        (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
        (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let store_dirspaceflows ~request_id ~base_ref ~branch_ref db repo dirspaceflows =
      let id = CCInt64.of_int (Repo.id repo) in
      let run =
        Abbs_future_combinators.List_result.iter
          ~f:(fun dirspaceflows ->
            Pgsql_io.Prepared_stmt.execute
              db
              Sql.insert_dirspace
              (CCList.replicate (CCList.length dirspaceflows) base_ref)
              (CCList.map
                 (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.dir; _ }; _ } -> dir)
                 dirspaceflows)
              (CCList.replicate (CCList.length dirspaceflows) id)
              (CCList.replicate (CCList.length dirspaceflows) branch_ref)
              (CCList.map
                 (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.workspace; _ }; _ } ->
                   workspace)
                 dirspaceflows)
              (CCList.map
                 (fun Terrat_change.{ Dirspaceflow.workflow; _ } ->
                   let module Dfwf = Terrat_change.Dirspaceflow.Workflow in
                   let module Wf = Terrat_base_repo_config_v1.Workflows.Entry in
                   CCOption.map_or
                     ~default:Terrat_base_repo_config_v1.Workflows.Entry.Lock_policy.Strict
                     (fun { Dfwf.workflow = { Wf.lock_policy; _ }; _ } -> lock_policy)
                     workflow)
                 dirspaceflows))
          (CCList.chunks 500 dirspaceflows)
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let fetch_plan ~request_id db work_manifest_id dirspace =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_recent_plan
          ~f:CCFun.id
          work_manifest_id
          dirspace.Terrat_dirspace.dir
          dirspace.Terrat_dirspace.workspace
        >>= function
        | [] -> Abb.Future.return (Ok None)
        | data :: _ ->
            Pgsql_io.Prepared_stmt.execute
              db
              (Sql.delete_plan ())
              work_manifest_id
              dirspace.Terrat_dirspace.dir
              dirspace.Terrat_dirspace.workspace
            >>= fun () -> Abb.Future.return (Ok (Some data))
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let store_plan ~request_id db work_manifest_id dirspace data has_changes =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.execute
        db
        Sql.upsert_plan
        work_manifest_id
        dirspace.Terrat_dirspace.dir
        dirspace.Terrat_dirspace.workspace
        data
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let cleanup_plans ~request_id db =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.execute db Sql.delete_old_plans
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s: ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let work_manifest_result result =
      let module Wmr = Terrat_api_components.Work_manifest_dirspace_result in
      let module R = Terrat_api_components_work_manifest_tf_operation_result in
      let module Hooks_output = Terrat_api_components.Hook_outputs in
      let success = result.R.overall.R.Overall.success in
      let pre_hooks_status =
        let module Run = Terrat_api_components.Workflow_output_run in
        let module Env = Terrat_api_components.Workflow_output_env in
        let module Checkout = Terrat_api_components.Workflow_output_checkout in
        let module Ce = Terrat_api_components.Workflow_output_cost_estimation in
        let module Oidc = Terrat_api_components.Workflow_output_oidc in
        result.R.overall.R.Overall.outputs.Hooks_output.pre
        |> CCList.for_all
             Hooks_output.Pre.Items.(
               function
               | Workflow_output_run Run.{ success; _ }
               | Workflow_output_env Env.{ success; _ }
               | Workflow_output_checkout Checkout.{ success; _ }
               | Workflow_output_cost_estimation Ce.{ success; _ }
               | Workflow_output_oidc Oidc.{ success; _ } -> success)
      in
      let post_hooks_status =
        let module Run = Terrat_api_components.Workflow_output_run in
        let module Env = Terrat_api_components.Workflow_output_env in
        let module Oidc = Terrat_api_components.Workflow_output_oidc in
        let module Drift_create_issue = Terrat_api_components.Workflow_output_drift_create_issue in
        result.R.overall.R.Overall.outputs.Hooks_output.post
        |> CCList.for_all
             Hooks_output.Post.Items.(
               function
               | Workflow_output_run Run.{ success; _ }
               | Workflow_output_env Env.{ success; _ }
               | Workflow_output_oidc Oidc.{ success; _ }
               | Workflow_output_drift_create_issue Drift_create_issue.{ success; _ } -> success)
      in
      let dirspaces_success =
        CCList.map
          (fun Wmr.{ path; workspace; success; _ } ->
            ({ Terrat_change.Dirspace.dir = path; workspace }, success))
          result.R.dirspaces
      in
      {
        Terrat_evaluator3.Work_manifest_result.overall_success = success;
        pre_hooks_success = pre_hooks_status;
        post_hooks_success = post_hooks_status;
        dirspaces_success;
      }

    let store_tf_operation_result ~request_id db work_manifest_id result =
      let module Rb = Terrat_api_components_work_manifest_tf_operation_result in
      let open Abb.Future.Infix_monad in
      Prmths.Counter.inc_one
        (Metrics.run_overall_result_count (Bool.to_string result.Rb.overall.Rb.Overall.success));
      Abbs_time_it.run
        (fun time ->
          Logs.info (fun m ->
              m "GITHUB_EVALUATOR : %s : DIRSPACE_RESULT_STORE : time=%f" request_id time))
        (fun () ->
          Abbs_future_combinators.List_result.iter
            ~f:(fun result ->
              let module Wmr = Terrat_api_components.Work_manifest_dirspace_result in
              Logs.info (fun m ->
                  m
                    "GITHUB_EVALUATOR : %s : RESULT_STORE : id=%a : dir=%s : workspace=%s : \
                     result=%s"
                    request_id
                    Uuidm.pp
                    work_manifest_id
                    result.Wmr.path
                    result.Wmr.workspace
                    (if result.Wmr.success then "SUCCESS" else "FAILURE"));
              Pgsql_io.Prepared_stmt.execute
                db
                Sql.insert_github_work_manifest_result
                work_manifest_id
                result.Wmr.path
                result.Wmr.workspace
                result.Wmr.success)
            result.Rb.dirspaces)
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)
      | Error `Error -> Abb.Future.return (Error `Error)

    let query_conflicting_work_manifests_in_repo ~request_id db pull_request dirspaces op =
      let run_type =
        match op with
        | `Plan -> Terrat_work_manifest3.Step.Plan
        | `Apply -> Terrat_work_manifest3.Step.Apply
      in
      let dirs = CCList.map (fun Terrat_change.Dirspace.{ dir; _ } -> dir) dirspaces in
      let workspaces =
        CCList.map (fun Terrat_change.Dirspace.{ workspace; _ } -> workspace) dirspaces
      in
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.update_abort_duplicate_work_manifests ())
          ~f:CCFun.id
          (CCInt64.of_int pull_request.Pull_request.repo.Repo.id)
          (CCInt64.of_int pull_request.Pull_request.id)
          run_type
          dirs
          workspaces
        >>= fun ids ->
        CCList.iter
          (fun id ->
            Logs.info (fun m ->
                m "GITHUB_EVALUATOR : %s : ABORTED_WORK_MANIFEST : %a" request_id Uuidm.pp id))
          ids;
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.select_conflicting_work_manifests_in_repo ())
          ~f:(fun id maybe_stale -> (id, maybe_stale))
          (CCInt64.of_int pull_request.Pull_request.repo.Repo.id)
          (CCInt64.of_int pull_request.Pull_request.id)
          run_type
          dirs
          workspaces
        >>= fun ids ->
        match
          CCList.partition_filter_map
            (function
              | id, true -> `Right id
              | id, false -> `Left id)
            ids
        with
        | (_ :: _ as conflicting), _ ->
            Abbs_future_combinators.List_result.map
              ~f:(query_work_manifest ~request_id db)
              conflicting
            >>= fun wms ->
            Abb.Future.return
              (Ok
                 (Some
                    (Terrat_evaluator3.Conflicting_work_manifests.Conflicting
                       (CCList.filter_map CCFun.id wms))))
        | _, (_ :: _ as maybe_stale) ->
            Abbs_future_combinators.List_result.map
              ~f:(query_work_manifest ~request_id db)
              maybe_stale
            >>= fun wms ->
            Abb.Future.return
              (Ok
                 (Some
                    (Terrat_evaluator3.Conflicting_work_manifests.Maybe_stale
                       (CCList.filter_map CCFun.id wms))))
        | _, _ -> Abb.Future.return (Ok None)
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok wms -> Abb.Future.return (Ok wms)
      | Error `Error -> Abb.Future.return (Error `Error)
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let fetch_pull_request_reviews ~request_id client pull_request =
      let open Abb.Future.Infix_monad in
      let repo = Pull_request.repo pull_request in
      let owner = Repo.owner repo in
      let repo = Repo.name repo in
      let pull_number = pull_request.Pull_request.id in
      Terrat_github.Pull_request_reviews.list ~owner ~repo ~pull_number client.Client.client
      >>= function
      | Ok reviews ->
          let module Prr = Githubc2_components.Pull_request_review in
          Abb.Future.return
            (Ok
               (CCList.map
                  (fun Prr.{ primary = Primary.{ node_id; state; user; _ }; _ } ->
                    Terrat_pull_request_review.
                      {
                        id = node_id;
                        status =
                          (match state with
                          | "APPROVED" -> Status.Approved
                          | _ -> Status.Unknown);
                        user =
                          CCOption.map
                            (fun Githubc2_components.Nullable_simple_user.
                                   { primary = Primary.{ login; _ }; _ } -> login)
                            user;
                      })
                  reviews))
      | Error (#Terrat_github.Pull_request_reviews.list_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : ERROR : %a"
                request_id
                Terrat_github.Pull_request_reviews.pp_list_err
                err);
          Abb.Future.return (Error `Error)

    let compute_approved request_id access_control_ctx approved approved_reviews =
      let module Match_set = CCSet.Make (Terrat_base_repo_config_v1.Access_control.Match) in
      let module Match_map = CCMap.Make (Terrat_base_repo_config_v1.Access_control.Match) in
      let open Abbs_future_combinators.Infix_result_monad in
      let module Tprr = Terrat_pull_request_review in
      let module Ac = Terrat_base_repo_config_v1.Apply_requirements.Approved in
      let { Ac.all_of; any_of; any_of_count; enabled } = approved in
      let combined_queries = Match_set.(to_list (of_list (all_of @ any_of))) in
      Abbs_future_combinators.List_result.fold_left
        ~init:Match_map.empty
        ~f:(fun acc query ->
          Abbs_future_combinators.List_result.filter_map
            ~f:(function
              | { Tprr.user = Some user; _ } -> (
                  let ctx = Access_control.set_user user access_control_ctx in
                  Access_control.query ctx query
                  >>= function
                  | true -> Abb.Future.return (Ok (Some user))
                  | false -> Abb.Future.return (Ok None))
              | _ -> Abb.Future.return (Ok None))
            approved_reviews
          >>= fun matching_reviews ->
          Abb.Future.return
            (Ok
               (CCList.fold_left
                  (fun acc user -> Match_map.add_to_list query user acc)
                  acc
                  matching_reviews)))
        combined_queries
      >>= fun matching_reviews ->
      let all_of_results = CCList.map (CCFun.flip Match_map.mem matching_reviews) all_of in
      let any_of_results =
        CCList.flatten (CCList.filter_map (CCFun.flip Match_map.find_opt matching_reviews) any_of)
      in
      let all_of_passed = CCList.for_all CCFun.id all_of_results in
      let any_of_passed =
        (CCList.is_empty any_of && CCList.length approved_reviews >= any_of_count)
        || ((not (CCList.is_empty any_of)) && CCList.length any_of_results >= any_of_count)
      in
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : COMPUTE_APPROVED : all_of_passed=%s : any_of_passed=%s"
            request_id
            (Bool.to_string all_of_passed)
            (Bool.to_string any_of_passed));
      (* Considered approved if all "all_of" passes and any "any_of" passes OR
         "all of" and "any of" are empty and the approvals is more than count *)
      Abb.Future.return (Ok (all_of_passed && any_of_passed))

    let eval_apply_requirements ~request_id config user client repo_config pull_request matches =
      let max_parallel = 20 in
      let module R = Terrat_base_repo_config_v1 in
      let module Ar = R.Apply_requirements in
      let module Abc = Ar.Check in
      let module Mc = Ar.Merge_conflicts in
      let module Sc = Ar.Status_checks in
      let module Ac = Ar.Approved in
      let open Abbs_future_combinators.Infix_result_monad in
      let log_time ?m request_id name t =
        Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : %s : %f" request_id name t);
        match m with
        | Some m -> Metrics.DefaultHistogram.observe m t
        | None -> ()
      in
      let filter_relevant_commit_checks ignore_matching_pats ignore_matching commit_checks =
        CCList.filter
          (fun Terrat_commit_check.{ title; _ } ->
            not
              (CCString.equal "terrateam apply" title
              || CCString.prefix ~pre:"terrateam apply:" title
              || CCString.prefix ~pre:"terrateam plan:" title
              || CCList.mem
                   ~eq:CCString.equal
                   title
                   [ "terrateam apply pre-hooks"; "terrateam apply post-hooks" ]
              || CCList.exists
                   CCFun.(Lua_pattern.find title %> CCOption.is_some)
                   ignore_matching_pats
              || CCList.exists (CCString.equal title) ignore_matching))
          commit_checks
      in
      let { Ar.checks; _ } = R.apply_requirements repo_config in
      let access_control_ctx =
        Access_control.Ctx.make
          ~client:client.Client.client
          ~config
          ~repo:(Pull_request.repo pull_request)
          ~user
          ()
      in
      Abbs_future_combinators.Infix_result_app.(
        (fun reviews commit_checks -> (reviews, commit_checks))
        <$> Abbs_time_it.run (log_time request_id "FETCH_APPROVED_TIME") (fun () ->
                fetch_pull_request_reviews ~request_id client pull_request)
        <*> Abbs_time_it.run (log_time request_id "FETCH_COMMIT_CHECKS_TIME") (fun () ->
                fetch_commit_checks
                  ~request_id
                  client
                  (Pull_request.repo pull_request)
                  (Pull_request.branch_ref pull_request)))
      >>= fun (reviews, commit_checks) ->
      let approved_reviews =
        CCList.filter
          (function
            | Terrat_pull_request_review.{ status = Status.Approved; _ } -> true
            | _ -> false)
          reviews
      in
      let merge_result =
        CCOption.get_or ~default:false pull_request.Pull_request.value.Pull_request.mergeable
      in
      if CCOption.is_none pull_request.Pull_request.value.Pull_request.mergeable then
        Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : MERGEABLE_NONE" request_id);
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.List_result.map
        ~f:(fun chunk ->
          Abbs_future_combinators.List_result.map
            ~f:(fun ({ Terrat_change_match3.Dirspace_config.tags; dirspace; _ } as match_) ->
              let open Abbs_future_combinators.Infix_result_monad in
              Logs.info (fun m ->
                  m
                    "GITHUB_EVALUATOR : %s : CHECK_APPLY_REQUIREMENTS : dir=%s : workspace=%s"
                    request_id
                    dirspace.Terrat_dirspace.dir
                    dirspace.Terrat_dirspace.workspace);
              match
                CCList.find_opt
                  (fun { Abc.tag_query; _ } ->
                    let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
                    Terrat_tag_query.match_ ~ctx ~tag_set:tags tag_query)
                  checks
              with
              | Some { Abc.tag_query; merge_conflicts; status_checks; approved; _ } ->
                  compute_approved request_id access_control_ctx approved approved_reviews
                  >>= fun approved_result ->
                  let ignore_matching = status_checks.Sc.ignore_matching in
                  (* Convert all patterns and ignore those that don't compile.  This eats
                     errors.

                     TODO: Improve handling errors here *)
                  let ignore_matching_pats =
                    CCList.filter_map Lua_pattern.of_string ignore_matching
                  in
                  (* Relevant checks exclude our terrateam checks, and also exclude any
                     ignored patterns.  We check both if a pattern matches OR if there is an
                     exact match with the string.  This is because someone might put in an
                     invalid pattern (because secretly we are using Lua patterns underneath
                     which have a slightly different syntax) *)
                  let relevant_commit_checks =
                    filter_relevant_commit_checks ignore_matching_pats ignore_matching commit_checks
                  in
                  let failed_commit_checks =
                    CCList.filter
                      (function
                        | Terrat_commit_check.{ status = Status.Completed; _ } -> false
                        | _ -> true)
                      relevant_commit_checks
                  in
                  let all_commit_check_success = CCList.is_empty failed_commit_checks in
                  let merged =
                    let module St = Terrat_pull_request.State in
                    match Pull_request.state pull_request with
                    | St.Merged _ -> true
                    | St.Open _ | St.Closed -> false
                  in
                  let passed =
                    merged
                    || ((not approved.Ac.enabled) || approved_result)
                       && ((not merge_conflicts.Mc.enabled) || merge_result)
                       && ((not status_checks.Sc.enabled) || all_commit_check_success)
                  in
                  let apply_requirements =
                    {
                      Apply_requirements.Result.passed;
                      match_;
                      approved = (if approved.Ac.enabled then Some approved_result else None);
                      merge_conflicts =
                        (if merge_conflicts.Mc.enabled then Some merge_result else None);
                      status_checks =
                        (if status_checks.Sc.enabled then Some all_commit_check_success else None);
                      status_checks_failed = failed_commit_checks;
                      approved_reviews;
                    }
                  in
                  Logs.info (fun m ->
                      m
                        "GITHUB_EVALUATOR : %s : APPLY_REQUIREMENTS_CHECKS : tag_query=%s \
                         approved=%s merge_conflicts=%s status_checks=%s"
                        request_id
                        (Terrat_tag_query.to_string tag_query)
                        (Bool.to_string approved.Ac.enabled)
                        (Bool.to_string merge_conflicts.Mc.enabled)
                        (Bool.to_string status_checks.Sc.enabled));
                  Logs.info (fun m ->
                      m
                        "GITHUB_EVALUATOR : %s : APPLY_REQUIREMENTS_RESULT : tag_query=%s \
                         approved=%s merge_check=%s commit_check=%s merged=%s passed=%s"
                        request_id
                        (Terrat_tag_query.to_string tag_query)
                        (Bool.to_string approved_result)
                        (Bool.to_string merge_result)
                        (Bool.to_string all_commit_check_success)
                        (Bool.to_string merged)
                        (Bool.to_string passed));
                  Abb.Future.return (Ok apply_requirements)
              | None ->
                  Abb.Future.return
                    (Ok
                       {
                         Apply_requirements.Result.passed = false;
                         match_;
                         approved = None;
                         merge_conflicts = None;
                         status_checks = None;
                         status_checks_failed = [];
                         approved_reviews = [];
                       }))
            chunk)
        (CCList.chunks (CCInt.max 1 (CCList.length matches / max_parallel)) matches)
      >>= function
      | Ok ret -> Abb.Future.return (Ok (CCList.flatten ret))
      | Error (`Error as ret) -> Abb.Future.return (Error ret)

    let query_dirspaces_owned_by_other_pull_requests ~request_id db pull_request dirspaces =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.fetch
        db
        (Sql.select_dirspaces_owned_by_other_pull_requests ())
        ~f:(fun
            dir
            workspace
            base_branch
            branch
            base_hash
            hash
            merged_hash
            merged_at
            pull_number
            state
            title
            user
          ->
          ( Terrat_change.Dirspace.{ dir; workspace },
            {
              Pull_request.base_branch_name = base_branch;
              base_ref = base_hash;
              branch_name = branch;
              branch_ref = hash;
              id = CCInt64.to_int pull_number;
              repo = pull_request.Pull_request.repo;
              state =
                (match (state, merged_hash, merged_at) with
                | "open", _, _ -> Terrat_pull_request.State.(Open Open_status.Mergeable)
                | "closed", _, _ -> Terrat_pull_request.State.Closed
                | "merged", Some merged_hash, Some merged_at ->
                    Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                | _ -> assert false);
              title;
              user;
              value = ();
            } ))
        (CCInt64.of_int pull_request.Pull_request.repo.Repo.id)
        (CCInt64.of_int pull_request.Pull_request.id)
        (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
        (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
      >>= function
      | Ok _ as res -> Abb.Future.return res
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let merge_pull_request' request_id client pull_request =
      let open Abbs_future_combinators.Infix_result_monad in
      let repo = pull_request.Pull_request.repo in
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %s : %s : %d"
            request_id
            repo.Repo.owner
            repo.Repo.name
            pull_request.Pull_request.id);
      Githubc2_abb.call
        client.Client.client
        Githubc2_pulls.Merge.(
          make
            ~body:
              Request_body.(
                make
                  Primary.(
                    make
                      ~commit_title:
                        (Some
                           (Printf.sprintf "Terrateam Automerge #%d" pull_request.Pull_request.id))
                      ()))
            Parameters.(
              make
                ~owner:repo.Repo.owner
                ~repo:repo.Repo.name
                ~pull_number:pull_request.Pull_request.id))
      >>= fun resp ->
      match Openapi.Response.value resp with
      | `OK _ -> Abb.Future.return (Ok ())
      | `Method_not_allowed _ -> (
          Logs.info (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGE_METHOD_NOT_ALLOWED : %s : %s : %d"
                request_id
                repo.Repo.owner
                repo.Repo.name
                pull_request.Pull_request.id);
          Githubc2_abb.call
            client.Client.client
            Githubc2_pulls.Merge.(
              make
                ~body:Request_body.(make Primary.(make ~merge_method:(Some "squash") ()))
                Parameters.(
                  make
                    ~owner:repo.Repo.owner
                    ~repo:repo.Repo.name
                    ~pull_number:pull_request.Pull_request.id))
          >>= fun resp ->
          match Openapi.Response.value resp with
          | `OK _ -> Abb.Future.return (Ok ())
          | ( `Method_not_allowed _
            | `Conflict _
            | `Forbidden _
            | `Not_found _
            | `Unprocessable_entity _ ) as err -> Abb.Future.return (Error err))
      | (`Conflict _ | `Forbidden _ | `Not_found _ | `Unprocessable_entity _) as err ->
          Abb.Future.return (Error err)

    let merge_pull_request ~request_id client pull_request =
      let open Abb.Future.Infix_monad in
      merge_pull_request' request_id client pull_request
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Githubc2_abb.call_err as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %a"
                request_id
                Githubc2_abb.pp_call_err
                err);
          Abb.Future.return (Error `Error)
      | Error
          (`Method_not_allowed
             Githubc2_pulls.Merge.Responses.Method_not_allowed.
               { primary = Primary.{ message = Some message; _ }; _ } as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %a"
                request_id
                Githubc2_pulls.Merge.Responses.pp
                err);
          Abb.Future.return (Error `Error)
      | Error (#Githubc2_pulls.Merge.Responses.t as err) ->
          Logs.err (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %a"
                request_id
                Githubc2_pulls.Merge.Responses.pp
                err);
          Abb.Future.return (Error `Error)

    let delete_pull_request_branch' request_id client pull_request =
      let open Abbs_future_combinators.Infix_result_monad in
      let repo = pull_request.Pull_request.repo in
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %d"
            request_id
            repo.Repo.owner
            repo.Repo.name
            pull_request.Pull_request.id);
      Terrat_github.fetch_pull_request
        ~owner:repo.Repo.owner
        ~repo:repo.Repo.name
        ~pull_number:pull_request.Pull_request.id
        client.Client.client
      >>= fun resp ->
      match Openapi.Response.value resp with
      | `OK
          Githubc2_components.Pull_request.
            {
              primary = Primary.{ head = Head.{ primary = Primary.{ ref_ = branch; _ }; _ }; _ };
              _;
            } -> (
          Logs.info (fun m ->
              m
                "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %d : %s"
                request_id
                repo.Repo.owner
                repo.Repo.name
                pull_request.Pull_request.id
                branch);
          Githubc2_abb.call
            client.Client.client
            Githubc2_git.Delete_ref.(
              make
                Parameters.(
                  make ~owner:repo.Repo.owner ~repo:repo.Repo.name ~ref_:("heads/" ^ branch)))
          >>= fun resp ->
          match Openapi.Response.value resp with
          | `No_content -> Abb.Future.return (Ok ())
          | `Unprocessable_entity err ->
              Logs.info (fun m ->
                  m
                    "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %d : %a"
                    request_id
                    repo.Repo.owner
                    repo.Repo.name
                    pull_request.Pull_request.id
                    Githubc2_git.Delete_ref.Responses.Unprocessable_entity.pp
                    err);
              Abb.Future.return (Ok ()))
      | (`Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _) as err ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.err (fun m ->
              m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Githubc2_pulls.Get.Responses.pp err);
          Abb.Future.return (Error `Error)

    let delete_pull_request_branch ~request_id client pull_request =
      let open Abb.Future.Infix_monad in
      delete_pull_request_branch' request_id client pull_request
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Githubc2_abb.call_err as err) ->
          Prmths.Counter.inc_one Metrics.github_errors_total;
          Logs.info (fun m ->
              m
                "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %a"
                request_id
                Githubc2_abb.pp_call_err
                err);
          Abb.Future.return (Error `Error)
      | Error `Error -> Abb.Future.return (Error `Error)

    let store_drift_schedule ~request_id db repo drift =
      let module D = Terrat_base_repo_config_v1.Drift in
      let open Abb.Future.Infix_monad in
      (if drift.D.enabled then
         Pgsql_io.Prepared_stmt.execute
           db
           Sql.upsert_drift_schedule
           (CCInt64.of_int repo.Repo.id)
           drift.D.schedule
           drift.D.reconcile
           (Some drift.D.tag_query)
       else
         Pgsql_io.Prepared_stmt.execute db Sql.delete_drift_schedule (CCInt64.of_int repo.Repo.id))
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Prmths.Counter.inc_one Metrics.pgsql_errors_total;
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let query_missing_drift_scheduled_runs ~request_id db =
      let open Abb.Future.Infix_monad in
      Pgsql_io.Prepared_stmt.fetch
        db
        (Sql.select_missing_drift_scheduled_runs ())
        ~f:(fun installation_id repository_id owner name _ _ ->
          ( { Account.installation_id = CCInt64.to_int installation_id },
            { Repo.id = CCInt64.to_int repository_id; owner; name } ))
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "GITHUB_EVALUATOR : %s : DRIFT : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let fetch_repo_config_with_provenance = Terratc.Github.Repo_config.fetch_with_provenance
  end

  module Evaluator = Terrat_evaluator3.Make (S)

  type run_err = [ `Error ] [@@deriving show]

  module State = Evaluator.State
  module Yield = Evaluator.Flow.Yield

  let run_pull_request_open ~ctx ~account ~user ~repo ~pull_request_id () =
    let open Abb.Future.Infix_monad in
    let event = Evaluator.Event.Pull_request_open { account; user; repo; pull_request_id } in
    Evaluator.run_event ctx event >>= fun _ -> Abb.Future.return (Ok ())

  let run_pull_request_close ~ctx ~account ~user ~repo ~pull_request_id () =
    let open Abb.Future.Infix_monad in
    let event = Evaluator.Event.Pull_request_close { account; user; repo; pull_request_id } in
    Evaluator.run_event ctx event >>= fun _ -> Abb.Future.return (Ok ())

  let run_pull_request_sync ~ctx ~account ~user ~repo ~pull_request_id () =
    let open Abb.Future.Infix_monad in
    let event = Evaluator.Event.Pull_request_sync { account; user; repo; pull_request_id } in
    Evaluator.run_event ctx event >>= fun _ -> Abb.Future.return (Ok ())

  let run_pull_request_ready_for_review ~ctx ~account ~user ~repo ~pull_request_id () =
    let open Abb.Future.Infix_monad in
    let event =
      Evaluator.Event.Pull_request_ready_for_review { account; user; repo; pull_request_id }
    in
    Evaluator.run_event ctx event >>= fun _ -> Abb.Future.return (Ok ())

  let run_pull_request_comment ~ctx ~account ~user ~comment ~repo ~pull_request_id ~comment_id () =
    let open Abb.Future.Infix_monad in
    let event =
      Evaluator.Event.Pull_request_comment
        { account; user; comment; repo; pull_request_id; comment_id }
    in
    Evaluator.run_event ctx event >>= fun _ -> Abb.Future.return (Ok ())

  let run_push ~ctx ~account ~user ~repo ~branch () =
    let open Abb.Future.Infix_monad in
    let event = Evaluator.Event.Push { account; user; repo; branch } in
    Evaluator.run_event ctx event >>= fun _ -> Abb.Future.return (Ok ())

  let work_manifest_initiate ~ctx ~encryption_key work_manifest_id initiate =
    Evaluator.run_work_manifest_initiate ctx encryption_key work_manifest_id initiate

  let work_manifest_result ~ctx work_manifest_id result =
    Evaluator.run_work_manifest_result ctx work_manifest_id result

  let work_manifest_failure ~ctx work_manifest_id =
    Evaluator.run_work_manifest_failure ctx work_manifest_id

  let plan_store ~ctx work_manifest_id plan = Evaluator.run_plan_store ctx work_manifest_id plan

  let plan_fetch ~ctx work_manifest_id dirspace =
    Evaluator.run_plan_fetch ctx work_manifest_id dirspace

  module Service = struct
    let one_hour = Duration.to_f (Duration.of_hour 1)

    let rec drift config storage =
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.ignore
        (Evaluator.run_scheduled_drift
           (Terrat_evaluator3.Ctx.make
              ~config
              ~storage
              ~request_id:(Uuidm.to_string (Uuidm.v `V4))
              ()))
      >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> drift config storage

    let rec flow_state_cleanup config storage =
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.ignore
        (Evaluator.run_flow_state_cleanup
           (Terrat_evaluator3.Ctx.make
              ~config
              ~storage
              ~request_id:(Uuidm.to_string (Uuidm.v `V4))
              ()))
      >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> flow_state_cleanup config storage

    let rec plan_cleanup config storage =
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.ignore
        (Evaluator.run_plan_cleanup
           (Terrat_evaluator3.Ctx.make
              ~config
              ~storage
              ~request_id:(Uuidm.to_string (Uuidm.v `V4))
              ()))
      >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> plan_cleanup config storage

    let rec repo_config_cleanup config storage =
      let open Abb.Future.Infix_monad in
      Abbs_future_combinators.ignore
        (Evaluator.run_repo_config_cleanup
           (Terrat_evaluator3.Ctx.make
              ~config
              ~storage
              ~request_id:(Uuidm.to_string (Uuidm.v `V4))
              ()))
      >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> repo_config_cleanup config storage
  end
end
