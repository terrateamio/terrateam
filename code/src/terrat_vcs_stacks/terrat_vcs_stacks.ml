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
         and type db = S.Db.t) =
struct
  let store ~request_id ~pull_request config db = raise (Failure "nyi")
  let query ~request_id ~account ~repo_id ~pull_request_id db = raise (Failure "nyi")
end
