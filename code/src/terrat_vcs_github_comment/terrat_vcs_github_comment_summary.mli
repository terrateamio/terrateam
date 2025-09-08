module Api = Terrat_vcs_api_github
module Publisher_tools = Terrat_vcs_github_comment_publishers.Publisher_tools

module S : sig
  type t = {
    client : Api.Client.t;
    config : Api.Config.t;
    db : Pgsql_io.t;
    pull_request : (unit, unit) Api.Pull_request.t;
    request_id : string;
    repo_config : Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t;
    synthesized_config : Terrat_change_match3.Config.t;
  }

  type el = {
    dirspace : Terrat_dirspace.t;
    is_success : bool;
    status : string;
    stats : Terrat_vcs_comment_summary.tf_stats;
  }
  [@@deriving show]

  type comment_id = Api.Comment.Id.t [@@deriving ord, show]

  val query_comment_id :
    t ->
    pull_number:int64 ->
    repo:int64 ->
    (comment_id option, [> `Error ]) result Abb_scheduler_kqueue.Future.t

  val query_summary_elements :
    t ->
    pull_number:int64 ->
    repo:int64 ->
    (el list, [> `Error ]) result Abb_scheduler_kqueue.Future.t

  val upsert_summary :
    t ->
    comment_id ->
    pull_number:int64 ->
    repo:int64 ->
    (unit, [> `Error ]) result Abb_scheduler_kqueue.Future.t

  val minimize_comment : t -> comment_id -> (unit, [> `Error ]) result Abb_scheduler_kqueue.Future.t

  val post_comment :
    t -> el list -> (comment_id, [> `Error ]) Abbs_future_combinators.Infix_result_monad.t

  val rendered_length : t -> el list -> int
  val pull_request : t -> int64
  val repo : t -> int64
  val repo_config : t -> Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t
  val compare_el : el -> el -> int
  val max_comment_length : int
end
