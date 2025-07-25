module Make (S : Terrat_vcs_provider2.S) : sig
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
end
