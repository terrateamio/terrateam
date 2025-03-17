module Api = Terrat_vcs_api_github

module type S = sig
  val work_manifest_url :
    Api.Config.t -> Api.Account.t -> ('a, 'b) Terrat_work_manifest3.Existing.t -> Uri.t option
end

module Unlock_id : sig
  type t

  val of_pull_request : Api.Pull_request.Id.t -> t
  val drift : unit -> t
  val to_string : t -> string
end

module Db : sig
  type t = Pgsql_io.t

  val store_account_repository :
    request_id:string -> t -> Api.Account.t -> Api.Repo.t -> (unit, [> `Error ]) result Abb.Future.t

  val store_pull_request :
    request_id:string ->
    t ->
    (Terrat_change.Diff.t list, bool) Api.Pull_request.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val store_index :
    request_id:string ->
    t ->
    Uuidm.t ->
    Terrat_api_components.Work_manifest_index_result.t ->
    (Terrat_vcs_provider2.Index.t, [> `Error ]) result Abb.Future.t

  val store_index_result :
    request_id:string ->
    t ->
    Uuidm.t ->
    Terrat_api_components.Work_manifest_index_result.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val store_repo_config_json :
    request_id:string ->
    t ->
    Api.Account.t ->
    Api.Ref.t ->
    Yojson.Safe.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val store_flow_state :
    request_id:string -> t -> Uuidm.t -> string -> (unit, [> `Error ]) result Abb.Future.t

  val store_dirspaceflows :
    request_id:string ->
    base_ref:Api.Ref.t ->
    branch_ref:Api.Ref.t ->
    t ->
    Api.Repo.t ->
    Terrat_change.Dirspaceflow.Workflow.t Terrat_change.Dirspaceflow.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val store_tf_operation_result :
    request_id:string ->
    t ->
    Uuidm.t ->
    Terrat_api_components_work_manifest_tf_operation_result.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val store_tf_operation_result2 :
    request_id:string ->
    t ->
    Uuidm.t ->
    Terrat_api_components_work_manifest_tf_operation_result2.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val store_drift_schedule :
    request_id:string ->
    t ->
    Api.Repo.t ->
    Terrat_base_repo_config_v1.Drift.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val query_account_status :
    request_id:string ->
    t ->
    Api.Account.t ->
    (Terrat_vcs_provider2.Account_status.t, [> `Error ]) result Abb.Future.t

  val query_index :
    request_id:string ->
    t ->
    Api.Account.t ->
    Api.Ref.t ->
    (Terrat_vcs_provider2.Index.t option, [> `Error ]) result Abb.Future.t

  val query_repo_config_json :
    request_id:string ->
    t ->
    Api.Account.t ->
    Api.Ref.t ->
    (Yojson.Safe.t option, [> `Error ]) result Abb.Future.t

  val query_next_pending_work_manifest :
    request_id:string ->
    t ->
    ( ( Api.Account.t,
        ((unit, unit) Api.Pull_request.t, Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      option,
      [> `Error ] )
    result
    Abb.Future.t

  val query_flow_state :
    request_id:string -> t -> Uuidm.t -> (string option, [> `Error ]) result Abb.Future.t

  val delete_flow_state :
    request_id:string -> t -> Uuidm.t -> (unit, [> `Error ]) result Abb.Future.t

  val query_pull_request_out_of_change_applies :
    request_id:string ->
    t ->
    ('diff, 'checks) Api.Pull_request.t ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_applied_dirspaces :
    request_id:string ->
    t ->
    ('diff, 'checks) Api.Pull_request.t ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_dirspaces_without_valid_plans :
    request_id:string ->
    t ->
    ('diff, 'checks) Api.Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_conflicting_work_manifests_in_repo :
    request_id:string ->
    t ->
    ('diff, 'checks) Api.Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    [< `Plan | `Apply ] ->
    ( ( Api.Account.t,
        ((unit, unit) Api.Pull_request.t, Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      Terrat_vcs_provider2.Conflicting_work_manifests.t
      option,
      [> `Error ] )
    result
    Abb.Future.t

  val query_dirspaces_owned_by_other_pull_requests :
    request_id:string ->
    t ->
    ('diff, 'checks) Api.Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    ((Terrat_change.Dirspace.t * (unit, unit) Api.Pull_request.t) list, [> `Error ]) result
    Abb.Future.t

  val query_missing_drift_scheduled_runs :
    request_id:string ->
    t ->
    ((string * Api.Account.t * Api.Repo.t * bool * Terrat_tag_query.t) list, [> `Error ]) result
    Abb.Future.t

  val cleanup_repo_configs : request_id:string -> t -> (unit, [> `Error ]) result Abb.Future.t
  val cleanup_flow_states : request_id:string -> t -> (unit, [> `Error ]) result Abb.Future.t
  val cleanup_plans : request_id:string -> t -> (unit, [> `Error ]) result Abb.Future.t

  val unlock :
    request_id:string -> t -> Api.Repo.t -> Unlock_id.t -> (unit, [> `Error ]) result Abb.Future.t

  val query_plan :
    request_id:string ->
    t ->
    Uuidm.t ->
    Terrat_dirspace.t ->
    (string option, [> `Error ]) result Abb.Future.t

  val store_plan :
    request_id:string ->
    t ->
    Uuidm.t ->
    Terrat_dirspace.t ->
    string ->
    bool ->
    (unit, [> `Error ]) result Abb.Future.t
end

module Apply_requirements : sig
  module Result : sig
    type t

    val passed : t -> bool
    val approved_reviews : t -> Terrat_pull_request_review.t list
  end

  val eval :
    request_id:string ->
    Api.Config.t ->
    Api.User.t ->
    Api.Client.t ->
    'a Terrat_base_repo_config_v1.t ->
    ('diff, 'checks) Api.Pull_request.t ->
    Terrat_change_match3.Dirspace_config.t list ->
    (Result.t, [> `Error ]) result Abb.Future.t
end

module Comment (S : S) : sig
  val publish_comment :
    request_id:string ->
    Api.Client.t ->
    string ->
    ('diff, 'checks) Api.Pull_request.t ->
    ( Api.Account.t,
      ('diff1, 'checks1) Api.Pull_request.t,
      (('diff2, 'checks2) Api.Pull_request.t, Api.Repo.t) Terrat_vcs_provider2.Target.t,
      Apply_requirements.Result.t,
      Api.Config.t )
    Terrat_vcs_provider2.Msg.t ->
    (unit, [> `Error ]) result Abb.Future.t
end

module Work_manifest : sig
  val run :
    request_id:string ->
    Api.Config.t ->
    Api.Client.t ->
    ( Api.Account.t,
      ((unit, unit) Api.Pull_request.t, Api.Repo.t) Terrat_vcs_provider2.Target.t )
    Terrat_work_manifest3.Existing.t ->
    (unit, [> `Failed_to_start | `Missing_workflow | `Error ]) result Abb.Future.t

  val create :
    request_id:string ->
    Db.t ->
    ( Api.Account.t,
      ((unit, unit) Api.Pull_request.t, Api.Repo.t) Terrat_vcs_provider2.Target.t )
    Terrat_work_manifest3.New.t ->
    ( ( Api.Account.t,
        ((unit, unit) Api.Pull_request.t, Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t,
      [> `Error ] )
    result
    Abb.Future.t

  val query :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    ( ( Api.Account.t,
        ((unit, unit) Api.Pull_request.t, Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      option,
      [> `Error ] )
    result
    Abb.Future.t

  val update_state :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    Terrat_work_manifest3.State.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val update_run_id :
    request_id:string -> Db.t -> Uuidm.t -> string -> (unit, [> `Error ]) result Abb.Future.t

  val update_changes :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    int Terrat_change.Dirspaceflow.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val update_denied_dirspaces :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    Terrat_work_manifest3.Deny.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val update_steps :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    Terrat_work_manifest3.Step.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val result :
    Terrat_api_components_work_manifest_tf_operation_result.t ->
    Terrat_vcs_provider2.Work_manifest_result.t

  val result2 :
    Terrat_api_components_work_manifest_tf_operation_result2.t ->
    Terrat_vcs_provider2.Work_manifest_result.t
end
