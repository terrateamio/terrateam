module type M = sig
  type repo_id
  type pull_request_id
  type db

  val query_pull_request_core_id :
    request_id:string ->
    repo_id:repo_id ->
    pull_request_id:pull_request_id ->
    db ->
    (Uuidm.t, [> `Error ]) result Abb.Future.t
end

module Make
    (S : Terrat_vcs_provider2.S)
    (M :
      M
        with type repo_id = S.Api.Repo.Id.t
         and type pull_request_id = S.Api.Pull_request.Id.t
         and type db = S.Db.t) : sig
  val store :
    request_id:string ->
    pull_request:('a, 'b) S.Api.Pull_request.t ->
    Terrat_change_match3.Config.t ->
    S.Db.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val query :
    request_id:string ->
    account:S.Api.Account.Id.t ->
    repo_id:S.Api.Repo.Id.t ->
    pull_request_id:S.Api.Pull_request.Id.t ->
    S.Db.t ->
    (Terrat_api_components.Stacks.t, [> `Error ]) result Abb.Future.t
end
