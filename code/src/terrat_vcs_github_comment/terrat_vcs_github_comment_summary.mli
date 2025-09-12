module Api = Terrat_vcs_api_github

module S : sig
  type t = {
    account_status : Terrat_vcs_provider2.Account_status.t;
    client : Api.Client.t;
    config : Api.Config.t;
    db : Pgsql_io.t;
    pull_request : (unit, unit) Api.Pull_request.t;
    request_id : string;
    result : Terrat_api_components_work_manifest_tf_operation_result2.t;
    repo_config : Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t;
    synthesized_config : Terrat_change_match3.Config.t;
    work_manifest : (Api.Account.t, unit) Terrat_work_manifest3.Existing.t;
  }

  type el = {
    dirspace : Terrat_dirspace.t;
    is_success : bool;
    stats : Terrat_vcs_comment_summary.tf_stats;
    work_manifest_id : Uuidm.t;
  }
  [@@deriving show]

  type comment_id = Api.Comment.Id.t [@@deriving ord, show]

  val query_comment_id :
    t ->
    pull_number:string ->
    repo:string ->
    (comment_id option option, [> `Error ]) result Abb.Future.t

  val query_summary_elements :
    t ->
    pull_number:string ->
    repo:string ->
    (el list, [> `Error ]) result Abb.Future.t

  val upsert_summary : t -> comment_id -> (unit, [> `Error ]) result Abb.Future.t
  val minimize_comment : t -> comment_id -> (unit, [> `Error ]) result Abb.Future.t
  val post_comment : t -> el list -> (comment_id, [> `Error ]) result Abb.Future.t
  val rendered_length : t -> el list -> int
  val pull_request : t -> int64
  val repo : t -> int64
  val max_comment_length : int
end
