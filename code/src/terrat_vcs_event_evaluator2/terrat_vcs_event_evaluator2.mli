module Make (S : Terrat_vcs_provider2.S) : sig
  type err = Terrat_vcs_event_evaluator2_builder.Make(S).err

  module Pull_request_event : sig
    type t =
      | Open
      | Close
      | Sync
      | Ready_for_review
      | Comment of {
          comment_id : int;
          comment : Terrat_comment.t;
        }
  end

  val pull_request_event :
    request_id:string ->
    config:S.Api.Config.t ->
    storage:Terrat_storage.t ->
    account:S.Api.Account.t ->
    repo:S.Api.Repo.t ->
    pull_request_id:S.Api.Pull_request.Id.t ->
    user:S.Api.User.t ->
    Pull_request_event.t ->
    unit Abb.Future.t

  val work_manifest_job_failed :
    request_id:string ->
    config:S.Api.Config.t ->
    storage:Terrat_storage.t ->
    account:S.Api.Account.t ->
    repo:S.Api.Repo.t ->
    run_id:string ->
    unit ->
    unit Abb.Future.t

  val compute_node_poll :
    request_id:string ->
    config:S.Api.Config.t ->
    storage:Terrat_storage.t ->
    compute_node_id:Uuidm.t ->
    Terrat_api_components.Work_manifest_initiate.t ->
    (Terrat_api_components.Work_manifest.t, [> `Error ]) result Abb.Future.t

  val work_manifest_result :
    request_id:string ->
    config:S.Api.Config.t ->
    storage:Terrat_storage.t ->
    work_manifest_id:Uuidm.t ->
    Terrat_api_components.Work_manifest_result.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val push :
    request_id:string ->
    config:S.Api.Config.t ->
    storage:Terrat_storage.t ->
    account:S.Api.Account.t ->
    repo:S.Api.Repo.t ->
    branch:S.Api.Ref.t ->
    user:S.Api.User.t ->
    unit ->
    unit Abb.Future.t

  val run_missing_drift_schedules :
    config:S.Api.Config.t -> storage:Terrat_storage.t -> unit -> unit Abb.Future.t
end
