module Make (S : Terrat_vcs_provider2.S) : sig
  type err = Terrat_vcs_event_evaluator2_builder.Make(S).err

  val pull_request_job :
    ?comment_id:int ->
    request_id:string ->
    config:S.Api.Config.t ->
    storage:Terrat_storage.t ->
    account:S.Api.Account.t ->
    repo:S.Api.Repo.t ->
    pull_request_id:S.Api.Pull_request.Id.t ->
    user:S.Api.User.t ->
    Terrat_job_context.Job.Type_.t ->
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
end
