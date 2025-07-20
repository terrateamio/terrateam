module Make (S : Terrat_vcs_provider2.S) : sig
  module Key : sig
    type 'a t
  end

  type repo_config_fetch_err = Terrat_vcs_provider2.fetch_repo_config_with_provenance_err
  [@@deriving show]

  type err =
    [ `Missing_dep_err of string
    | `Error
    | `Closed
    | repo_config_fetch_err
    | Terrat_change_match3.synthesize_config_err
    ]
  [@@deriving show]

  val pull_request_comment :
    config:S.Api.Config.t ->
    storage:Terrat_storage.t ->
    account:S.Api.Account.t ->
    comment:Terrat_comment.t ->
    repo:S.Api.Repo.t ->
    pull_request_id:S.Api.Pull_request.Id.t ->
    comment_id:int ->
    user:S.Api.User.t ->
    unit ->
    unit Abb.Future.t
end
