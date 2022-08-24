module Dir_set : module type of CCSet.Make (CCString)
module Dirspace_map : module type of CCMap.Make (Terrat_change.Dirspace)

module Msg : sig
  type 'pull_request t =
    | Missing_plans of Terrat_change.Dirspace.t list
    | Dirspaces_owned_by_other_pull_request of 'pull_request Dirspace_map.t
    | Conflicting_work_manifests of 'pull_request Terrat_work_manifest.Existing_lite.t list
    | Repo_config_parse_failure of string
    | Repo_config_failure of string
    | Pull_request_not_appliable of 'pull_request
    | Pull_request_not_mergeable of 'pull_request
    | Apply_no_matching_dirspaces
    | Plan_no_matching_dirspaces
    | Base_branch_not_default_branch of 'pull_request
    | Autoapply_running
    | Bad_glob of string
end

module type S = sig
  module Event : sig
    type t

    val request_id : t -> string
    val run_type : t -> Terrat_work_manifest.Run_type.t
    val tag_query : t -> Terrat_tag_set.t
    val default_branch : t -> string
  end

  module Pull_request : sig
    type t

    val base_branch_name : t -> string
    val base_hash : t -> string
    val hash : t -> string
    val diff : t -> Terrat_change.Diff.t list
    val state : t -> Terrat_pull_request.State.t
    val passed_all_checks : t -> bool
    val mergeable : t -> bool option
    val is_draft_pr : t -> bool
  end

  (** Given a set of directories, return those directories that exist in the repo *)
  val list_existing_dirs :
    Event.t -> Pull_request.t -> Dir_set.t -> (Dir_set.t, [> `Error ]) result Abb.Future.t

  val store_dirspaceflows :
    Pgsql_io.t ->
    Event.t ->
    Pull_request.t ->
    Terrat_change.Dirspaceflow.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val store_new_work_manifest :
    Pgsql_io.t ->
    Event.t ->
    Pull_request.t Terrat_work_manifest.New.t ->
    (Pull_request.t Terrat_work_manifest.Existing_lite.t, [> `Error ]) result Abb.Future.t

  val store_pull_request :
    Pgsql_io.t -> Event.t -> Pull_request.t -> (unit, [> `Error ]) result Abb.Future.t

  val fetch_repo_config :
    Event.t ->
    Pull_request.t ->
    ( Terrat_repo_config.Version_1.t,
      [> `Repo_config_parse_err of string | `Repo_config_err of string ] )
    result
    Abb.Future.t

  val fetch_pull_request : Event.t -> (Pull_request.t, [> `Error ]) result Abb.Future.t
  val fetch_tree : Event.t -> Pull_request.t -> (string list, [> `Error ]) result Abb.Future.t

  val query_conflicting_work_manifests_in_repo :
    Pgsql_io.t ->
    Event.t ->
    (Pull_request.t Terrat_work_manifest.Existing_lite.t list, [> `Error ]) result Abb.Future.t

  val query_unapplied_dirspaces :
    Pgsql_io.t ->
    Event.t ->
    Pull_request.t ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_dirspaces_without_valid_plans :
    Pgsql_io.t ->
    Event.t ->
    Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_dirspaces_owned_by_other_pull_requests :
    Pgsql_io.t ->
    Event.t ->
    Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    (Pull_request.t Dirspace_map.t, [> `Error ]) result Abb.Future.t

  (** Return the list of changes that have happened for this PR that were done
     on a different hash than the passed in pull request. *)
  val query_pull_request_out_of_diff_applies :
    Pgsql_io.t ->
    Event.t ->
    Pull_request.t ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val publish_msg : Event.t -> Pull_request.t Msg.t -> unit Abb.Future.t
end

module Make (S : S) : sig
  val run : Terrat_storage.t -> S.Event.t -> unit Abb.Future.t
end
