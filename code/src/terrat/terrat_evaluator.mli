(** Defines the process for evaluating a Terrateam operation from initiation all
    the way to execution and reporting.  Work starts with an event initiated by
    a user (plan, apply, unlock, etc), to evaluating the event, executing the
    next operation, and managing the lifecycle of the work manifest.  *)

module Event : sig
  module Dir_set : module type of CCSet.Make (CCString)
  module Dirspace_map : module type of CCMap.Make (Terrat_change.Dirspace)

  module Msg : sig
    type ('pull_request, 'apply_requirements) t =
      | Missing_plans of Terrat_change.Dirspace.t list
      | Dirspaces_owned_by_other_pull_request of 'pull_request Dirspace_map.t
      | Conflicting_work_manifests of
          'pull_request Terrat_work_manifest.Pull_request.Existing_lite.t list
      | Repo_config_parse_failure of string
      | Repo_config_failure of string
      | Pull_request_not_appliable of ('pull_request * 'apply_requirements)
      | Pull_request_not_mergeable
      | Apply_no_matching_dirspaces
      | Plan_no_matching_dirspaces
      | Dest_branch_no_match of 'pull_request
      | Autoapply_running
      | Bad_glob of string
      | Access_control_denied of
          [ `All_dirspaces of Terrat_access_control.R.Deny.t list
          | `Dirspaces of Terrat_access_control.R.Deny.t list
          | `Invalid_query of string
          | `Lookup_err
          | `Terrateam_config_update of string list
          | `Terrateam_config_update_bad_query of string
          | `Unlock of string list
          ]
      | Unlock_success
  end

  module Op_class : sig
    type tf_mode =
      [ `Manual
      | `Auto
      ]
    [@@deriving show]

    type tf =
      [ `Apply of tf_mode
      | `Apply_autoapprove
      | `Apply_force
      | `Plan of tf_mode
      ]
    [@@deriving show]

    type t =
      | Terraform of tf
      | Pull_request of [ `Unlock of int list ]
    [@@deriving show]

    val run_type_of_tf : tf -> Terrat_work_manifest.Pull_request.Run_type.t
  end

  module Event_type : sig
    type t =
      | Apply
      | Apply_autoapprove
      | Apply_force
      | Autoapply
      | Autoplan
      | Plan
      | Unlock of int list
    [@@deriving show]

    val to_string : t -> string
  end
end

module Work_manifest : sig
  module Dirspace_map : module type of CCMap.Make (Terrat_change.Dirspace)

  type _ t = Pull_request : 'a Terrat_work_manifest.Pull_request.Existing.t -> 'a t
end

module type S = sig
  module Event : sig
    module T : sig
      type t

      val request_id : t -> string
      val event_type : t -> Event.Event_type.t
      val tag_query : t -> Terrat_tag_query.t
      val default_branch : t -> string
      val user : t -> string
    end

    module Pull_request : sig
      type t

      val base_branch_name : t -> string
      val base_hash : t -> string
      val hash : t -> string
      val diff : t -> Terrat_change.Diff.t list
      val state : t -> Terrat_pull_request.State.t
      val passed_all_checks : t -> bool
      val is_draft_pr : t -> bool
      val branch_name : t -> string
    end

    module Apply_requirements : sig
      type t

      val passed : t -> bool
      val approved_reviews : t -> Terrat_pull_request_review.t list
    end

    module Access_control : Terrat_access_control.S

    val create_access_control_ctx : user:string -> T.t -> Access_control.ctx

    val store_dirspaceflows :
      Pgsql_io.t ->
      T.t ->
      Pull_request.t ->
      Terrat_change.Dirspaceflow.t list ->
      (unit, [> `Error ]) result Abb.Future.t

    val store_pull_request_work_manifest :
      Pgsql_io.t ->
      T.t ->
      Terrat_repo_config.Version_1.t ->
      Terrat_change_match.t list ->
      Pull_request.t Terrat_work_manifest.Pull_request.New.t ->
      Terrat_access_control.R.Deny.t list ->
      (Pull_request.t Terrat_work_manifest.Pull_request.Existing_lite.t, [> `Error ]) result
      Abb.Future.t

    val store_pull_request :
      Pgsql_io.t -> T.t -> Pull_request.t -> (unit, [> `Error ]) result Abb.Future.t

    val fetch_base_repo_config :
      T.t ->
      ( Terrat_repo_config.Version_1.t,
        [> `Repo_config_parse_err of string | `Repo_config_err of string ] )
      result
      Abb.Future.t

    val fetch_repo_config :
      T.t ->
      Pull_request.t ->
      ( Terrat_repo_config.Version_1.t,
        [> `Repo_config_parse_err of string | `Repo_config_err of string ] )
      result
      Abb.Future.t

    val fetch_pull_request :
      T.t -> (Pull_request.t, [> `Merge_conflict | `Error ]) result Abb.Future.t

    val fetch_tree : T.t -> Pull_request.t -> (string list, [> `Error ]) result Abb.Future.t

    val check_apply_requirements :
      T.t ->
      Pull_request.t ->
      Terrat_repo_config.Version_1.t ->
      (Apply_requirements.t, [> `Error ]) result Abb.Future.t

    val query_conflicting_work_manifests_in_repo :
      Pgsql_io.t ->
      T.t ->
      Event.Op_class.tf ->
      (Pull_request.t Terrat_work_manifest.Pull_request.Existing_lite.t list, [> `Error ]) result
      Abb.Future.t

    val query_unapplied_dirspaces :
      Pgsql_io.t ->
      T.t ->
      Pull_request.t ->
      (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

    val query_dirspaces_without_valid_plans :
      Pgsql_io.t ->
      T.t ->
      Pull_request.t ->
      Terrat_change.Dirspace.t list ->
      (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

    val query_dirspaces_owned_by_other_pull_requests :
      Pgsql_io.t ->
      T.t ->
      Pull_request.t ->
      Terrat_change.Dirspace.t list ->
      (Pull_request.t Event.Dirspace_map.t, [> `Error ]) result Abb.Future.t

    (** Return the list of changes that have happened for this PR that were done
     on a different hash than the passed in pull request. *)
    val query_pull_request_out_of_diff_applies :
      Pgsql_io.t ->
      T.t ->
      Pull_request.t ->
      (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

    val unlock_pull_request :
      Terrat_storage.t -> T.t -> int -> (unit, [> `Error ]) result Abb.Future.t

    val publish_msg : T.t -> (Pull_request.t, Apply_requirements.t) Event.Msg.t -> unit Abb.Future.t
  end

  module Runner : sig
    val run : request_id:string -> Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
  end

  module Work_manifest : sig
    module Initiate : sig
      type t

      module Pull_request : sig
        type t [@@deriving show]

        module Lite : sig
          type t [@@deriving show]
        end
      end

      val request_id : t -> string

      val create :
        request_id:string ->
        work_manifest_id:Uuidm.t ->
        Terrat_config.t ->
        Terrat_storage.t ->
        Terrat_api_components.Work_manifest_initiate.t ->
        (t, [> `Work_manifest_not_found | `Error ]) result Abb.Future.t

      val to_response :
        t ->
        Pull_request.t Work_manifest.t ->
        (Terrat_api_components.Work_manifest.t, [> `Error ]) result Abb.Future.t

      val initiate_work_manifest :
        Pgsql_io.t -> t -> (Pull_request.t Work_manifest.t option, [> `Error ]) result Abb.Future.t

      val query_dirspaces_without_valid_plans :
        Pgsql_io.t ->
        t ->
        Pull_request.t ->
        Terrat_change.Dirspace.t list ->
        (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

      val query_dirspaces_owned_by_other_pull_requests :
        Pgsql_io.t ->
        t ->
        Pull_request.t ->
        Terrat_change.Dirspace.t list ->
        (Pull_request.Lite.t Work_manifest.Dirspace_map.t, [> `Error ]) result Abb.Future.t

      val work_manifest_already_run : t -> (unit, [> `Error ]) result Abb.Future.t
    end

    module Plans : sig
      val fetch :
        request_id:string ->
        path:string ->
        workspace:string ->
        Terrat_storage.t ->
        Uuidm.t ->
        (string option, [> `Error ]) result Abb.Future.t

      val store :
        request_id:string ->
        path:string ->
        workspace:string ->
        Terrat_storage.t ->
        Uuidm.t ->
        string ->
        (unit, [> `Error ]) result Abb.Future.t
    end

    module Results : sig
      val store :
        request_id:string ->
        Terrat_config.t ->
        Terrat_storage.t ->
        Uuidm.t ->
        Terrat_api_work_manifest.Results.Request_body.t ->
        (unit, [> `Error ]) result Abb.Future.t
    end
  end
end

module Make (S : S) : sig
  module Event : sig
    val eval : Terrat_storage.t -> S.Event.T.t -> unit Abb.Future.t
  end

  module Runner : sig
    val run : request_id:string -> Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
  end

  module Work_manifest : sig
    val initiate :
      request_id:string ->
      Terrat_config.t ->
      Terrat_storage.t ->
      Uuidm.t ->
      Terrat_api_components.Work_manifest_initiate.t ->
      Terrat_api_components.Work_manifest.t option Abb.Future.t

    val plan_fetch :
      request_id:string ->
      path:string ->
      workspace:string ->
      Terrat_storage.t ->
      Uuidm.t ->
      (string option, [> `Error ]) result Abb.Future.t

    val plan_store :
      request_id:string ->
      path:string ->
      workspace:string ->
      Terrat_storage.t ->
      Uuidm.t ->
      string ->
      (unit, [> `Error ]) result Abb.Future.t

    val results_store :
      request_id:string ->
      Terrat_config.t ->
      Terrat_storage.t ->
      Uuidm.t ->
      Terrat_api_work_manifest.Results.Request_body.t ->
      (unit, [> `Error ]) result Abb.Future.t
  end
end
