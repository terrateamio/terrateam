module Api = Terrat_vcs_api_nyi

module Unlock_id = struct
  type t =
    | Pull_request of int
    | Drift

  let of_pull_request id = Pull_request id
  let drift () = Drift

  let to_string = function
    | Pull_request id -> CCInt.to_string id
    | Drift -> "drift"
end

module Pull_request = struct
  type t

  let base_branch_name t = raise (Failure "nyi")
  let base_ref t = raise (Failure "nyi")
  let branch_name t = raise (Failure "nyi")
  let branch_ref t = raise (Failure "nyi")
  let id t = raise (Failure "nyi")
  let repo t = raise (Failure "nyi")
  let state t = raise (Failure "nyi")
end

module Db = struct
  type t = Pgsql_io.t

  let store_account_repository ~request_id db account repo = raise (Failure "nyi")
  let store_pull_request ~request_id db pull_request = raise (Failure "nyi")
  let store_index ~request_id db work_manifest_id index = raise (Failure "nyi")
  let store_index_result ~request_id db work_manifest_id index_result = raise (Failure "nyi")
  let store_repo_config_json ~request_id db account ref_ json = raise (Failure "nyi")
  let store_flow_state ~request_id db work_manifest_id state = raise (Failure "nyi")

  let store_dirspaceflows ~request_id ~base_ref ~branch_ref db repo dirspaceflows =
    raise (Failure "nyi")

  let store_tf_operation_result ~request_id db work_manifest_id result = raise (Failure "nyi")
  let store_tf_operation_result2 ~request_id db work_manifest_id result = raise (Failure "nyi")
  let store_drift_schedule ~request_id db repo drift = raise (Failure "nyi")
  let query_account_status ~request_id db account = raise (Failure "nyi")
  let query_index ~request_id db account ref_ = raise (Failure "nyi")
  let query_repo_config_json ~request_id db account ref_ = raise (Failure "nyi")
  let query_next_pending_work_manifest ~request_id db = raise (Failure "nyi")
  let query_flow_state ~request_id db work_manifest_id = raise (Failure "nyi")
  let delete_flow_state ~request_id db work_manifest_id = raise (Failure "nyi")
  let query_pull_request_out_of_change_applies ~request_id db pull_request = raise (Failure "nyi")
  let query_applied_dirspaces ~request_id db pull_request = raise (Failure "nyi")

  let query_dirspaces_without_valid_plans ~request_id db pull_request dirspaces =
    raise (Failure "nyi")

  let query_conflicting_work_manifests_in_repo ~request_id db pull_request dirspaces op =
    raise (Failure "nyi")

  let query_dirspaces_owned_by_other_pull_requests ~request_id db pull_request dirspaces =
    raise (Failure "nyi")

  let query_missing_drift_scheduled_runs ~request_id db = raise (Failure "nyi")
  let cleanup_repo_configs ~request_id db = raise (Failure "nyi")
  let cleanup_flow_states ~request_id db = raise (Failure "nyi")
  let cleanup_plans ~request_id db = raise (Failure "nyi")
  let unlock ~request_id db repo unlock_id = raise (Failure "nyi")
  let query_plan ~request_id db work_manifest_id dirspace = raise (Failure "nyi")
  let store_plan ~request_id db work_manifest_id dirspace data has_changes = raise (Failure "nyi")
end

module Apply_requirements = struct
  module Result = struct
    type t

    let passed t = raise (Failure "nyi")
    let approved_reviews t = raise (Failure "nyi")
  end

  let eval ~request_id config user client repo_config pull_request dirspace_configs =
    raise (Failure "nyi")
end

module Gate = struct
  let insert_approval ~request_id ~token ~approver pull_request db = raise (Failure "nyi")
  let eval ~request_id client dirspaces pull_request db = raise (Failure "nyi")
end

module Comment = struct
  let publish_comment ~request_id client user pull_request msg = raise (Failure "nyi")
end

module Repo_config = struct
  let fetch_with_provenance ?system_defaults ?built_config request_id client repo ref_ =
    raise (Failure "nyi")
end

module Access_control = struct
  module Ctx = struct
    type t

    let make ~client ~config ~repo ~user () = raise (Failure "nyi")
  end

  let query ctx mtch = raise (Failure "nyi")
  let is_ci_changed ctx diff = raise (Failure "nyi")
  let set_user user ctx = raise (Failure "nyi")
end

module Commit_check = struct
  let make ?work_manifest ~config ~description ~title ~status ~repo account = raise (Failure "nyi")
end

module Work_manifest = struct
  let run ~request_id config client = raise (Failure "nyi")
  let create ~request_id db work_manifest = raise (Failure "nyi")
  let query ~request_id db work_manifest_id = raise (Failure "nyi")
  let update_state ~request_id db work_manifest_id state = raise (Failure "nyi")
  let update_run_id ~request_id db work_manifest_id run_id = raise (Failure "nyi")
  let update_changes ~request_id db work_manifest_id dirspaceflows = raise (Failure "nyi")
  let update_denied_dirspaces ~request_id db work_manifest_id denies = raise (Failure "nyi")
  let update_steps ~request_id db work_manifest_id steps = raise (Failure "nyi")
  let result result = raise (Failure "nyi")
  let result2 result = raise (Failure "nyi")
end

module Ui = struct
  let work_manifest_url config account = raise (Failure "nyi")
end
