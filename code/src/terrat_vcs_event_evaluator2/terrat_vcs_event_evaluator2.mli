module Make (S : Terrat_vcs_provider2.S) : sig
  type err = Terrat_vcs_event_evaluator2_builder.Make(S).err

  val publish_repo_config :
    request_id:string ->
    config:S.Api.Config.t ->
    storage:Terrat_storage.t ->
    account:S.Api.Account.t ->
    repo:S.Api.Repo.t ->
    pull_request_id:S.Api.Pull_request.Id.t ->
    comment_id:int ->
    user:S.Api.User.t ->
    unit ->
    unit Abb.Future.t

  val compute_node_poll :
    request_id:string ->
    config:S.Api.Config.t ->
    storage:Terrat_storage.t ->
    compute_node_id:Uuidm.t ->
    Terrat_api_components.Work_manifest_initiate.t ->
    (Terrat_api_components.Work_manifest.t, [> err ]) result Abb.Future.t

  val work_manifest_result :
    request_id:string ->
    config:S.Api.Config.t ->
    storage:Terrat_storage.t ->
    work_manifest_id:Uuidm.t ->
    Terrat_api_components.Work_manifest_result.t ->
    (unit, [> err ]) result Abb.Future.t
end
