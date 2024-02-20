(** Defines the process for evaluating a Terrateam operation from initiation all
    the way to execution and reporting.  Work starts with an event initiated by
    a user (plan, apply, unlock, etc), to evaluating the event, executing the
    next operation, and managing the lifecycle of the work manifest.  *)

module Event : sig
  module Dir_set : module type of CCSet.Make (CCString)
  module Dirspace_map : module type of CCMap.Make (Terrat_change.Dirspace)

  module Msg : sig
    type ('pull_request, 'src, 'apply_requirements) t =
      | Missing_plans of Terrat_change.Dirspace.t list
      | Dirspaces_owned_by_other_pull_request of (Terrat_change.Dirspace.t * 'pull_request) list
      | Conflicting_work_manifests of 'src Terrat_work_manifest.Existing_lite.t list
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
      | Tag_query_err of Terrat_tag_query_ast.err
      | Account_expired
      | Repo_config of (Terrat_repo_config_version_1.t * Terrat_change_match.Dirs.t)
      | Unexpected_temporary_err
  end

  module Unlock_id : sig
    type t =
      | Pull_request of int
      | Drift
    [@@deriving show]
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
      | Pull_request of [ `Unlock of Unlock_id.t list ]
      | Repo_config
      | Index
    [@@deriving show]

    val run_type_of_tf : [< tf ] -> Terrat_work_manifest.Run_type.t
  end

  module Event_type : sig
    type t =
      | Apply
      | Apply_autoapprove
      | Apply_force
      | Autoapply
      | Autoplan
      | Plan
      | Unlock of Unlock_id.t list
      | Repo_config
      | Index
    [@@deriving show]

    val to_string : t -> string
  end
end

module Work_manifest : sig
  module Dirspace_map : module type of CCMap.Make (Terrat_change.Dirspace)

  type 'a t = 'a Terrat_work_manifest.Existing.t
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
      val work_manifest_id : t -> Uuidm.t option
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

    module Index : sig
      type t

      val of_pull_request : Pull_request.t -> t
    end

    module Src : sig
      type t
    end

    module Apply_requirements : sig
      type t

      val passed : t -> bool
      val approved_reviews : t -> Terrat_pull_request_review.t list
    end

    module Access_control : Terrat_access_control.S

    val create_access_control_ctx : user:string -> T.t -> Access_control.ctx

    val query_account_status :
      Pgsql_io.t -> T.t -> ([ `Active | `Expired | `Disabled ], [> `Error ]) result Abb.Future.t

    val store_dirspaceflows :
      Pgsql_io.t ->
      T.t ->
      Pull_request.t ->
      Terrat_change.Dirspaceflow.Workflow.t Terrat_change.Dirspaceflow.t list ->
      (unit, [> `Error ]) result Abb.Future.t

    val fetch_work_manifest :
      request_id:string ->
      Pgsql_io.t ->
      Uuidm.t ->
      string ->
      (unit Terrat_work_manifest.Existing_lite.t, [> `Error ]) result Abb.Future.t

    val update_pull_request_work_manifest :
      Pgsql_io.t ->
      T.t ->
      Terrat_repo_config.Version_1.t ->
      Terrat_change_match.t list ->
      Pull_request.t Terrat_work_manifest.Existing.t ->
      (Pull_request.t Terrat_work_manifest.Existing.t, [> `Error ]) result Abb.Future.t

    val store_pull_request_work_manifest :
      Pgsql_io.t ->
      T.t ->
      Terrat_repo_config.Version_1.t ->
      Terrat_change_match.t list ->
      Pull_request.t Terrat_work_manifest.New.t ->
      (Pull_request.t Terrat_work_manifest.Existing.t, [> `Error ]) result Abb.Future.t

    val store_index_work_manifest :
      Pgsql_io.t ->
      T.t ->
      Terrat_change_match.t list ->
      Index.t Terrat_work_manifest.New.t ->
      (Index.t Terrat_work_manifest.Existing.t, [> `Error ]) result Abb.Future.t

    val store_pull_request :
      Pgsql_io.t -> T.t -> Pull_request.t -> (unit, [> `Error ]) result Abb.Future.t

    val query_index :
      Pgsql_io.t ->
      T.t ->
      Pull_request.t ->
      (Terrat_change_match.Index.t option, [> `Error ]) result Abb.Future.t

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

    val fetch_pull_request : T.t -> (Pull_request.t, [> `Error ]) result Abb.Future.t
    val fetch_tree : T.t -> Pull_request.t -> (string list, [> `Error ]) result Abb.Future.t
    val fetch_base_tree : T.t -> Pull_request.t -> (string list, [> `Error ]) result Abb.Future.t

    val check_apply_requirements :
      T.t ->
      Pull_request.t ->
      Terrat_repo_config.Version_1.t ->
      (Apply_requirements.t, [> `Error ]) result Abb.Future.t

    val query_conflicting_work_manifests_in_repo :
      Pgsql_io.t ->
      T.t ->
      Terrat_change.Dirspace.t list ->
      [< Event.Op_class.tf ] ->
      (Src.t Terrat_work_manifest.Existing_lite.t list, [> `Error ]) result Abb.Future.t

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
      ((Terrat_change.Dirspace.t * Pull_request.t) list, [> `Error ]) result Abb.Future.t

    (** Return the list of changes that have happened for this PR that were done
     on a different hash than the passed in pull request. *)
    val query_pull_request_out_of_diff_applies :
      Pgsql_io.t ->
      T.t ->
      Pull_request.t ->
      (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

    val perform_unlock :
      Terrat_storage.t -> T.t -> Event.Unlock_id.t -> (unit, [> `Error ]) result Abb.Future.t

    val publish_msg :
      T.t -> (Pull_request.t, Src.t, Apply_requirements.t) Event.Msg.t -> unit Abb.Future.t
  end

  module Drift : sig
    module Schedule : sig
      type t [@@deriving show]

      val id : t -> string
      val owner : t -> string
      val name : t -> string
      val reconcile : t -> bool
    end

    module Repo : sig
      type t

      val tree : t -> string list
      val repo_config : t -> Terrat_repo_config.Version_1.t
      val index : t -> Terrat_change_match.Index.t option
    end

    val query_missing_scheduled_runs :
      Terrat_config.t -> Pgsql_io.t -> (Schedule.t list, [> `Error ]) result Abb.Future.t

    val fetch_repo :
      Terrat_config.t -> Pgsql_io.t -> Schedule.t -> (Repo.t, [> `Error ]) result Abb.Future.t

    val store_plan_work_manifest :
      Terrat_config.t ->
      Pgsql_io.t ->
      Schedule.t ->
      Repo.t ->
      Terrat_change.Dirspaceflow.Workflow.t Terrat_change.Dirspaceflow.t list ->
      (unit, [> `Error ]) result Abb.Future.t

    val store_reconcile_work_manifest :
      Terrat_config.t ->
      Pgsql_io.t ->
      Schedule.t ->
      Repo.t ->
      Terrat_change.Dirspaceflow.Workflow.t Terrat_change.Dirspaceflow.t list ->
      (unit, [> `Error ]) result Abb.Future.t
  end

  module Runner : sig
    val run : request_id:string -> Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
  end

  module Work_manifest : sig
    module Initiate : sig
      module Pull_request : sig
        module Lite : sig
          type t [@@deriving show]
        end
      end

      type t

      val work_manifest_state : t -> Terrat_work_manifest.State.t
      val work_manifest_run_type : t -> Terrat_work_manifest.Run_type.t
      val work_manifest_run_kind : t -> string

      val fetch_drift_repo :
        Terrat_storage.t -> t -> (Drift.Repo.t, [> `Error ]) result Abb.Future.t

      val update_drift_work_manifest :
        Terrat_storage.t ->
        t ->
        Terrat_change.Dirspaceflow.Workflow.t Terrat_change.Dirspaceflow.t list ->
        (t, [> `Error ]) result Abb.Future.t

      val reify_event :
        string ->
        Terrat_config.t ->
        Terrat_storage.t ->
        t ->
        (Event.T.t, [> `Error ]) result Abb.Future.t

      val make_index_work_manifest :
        t -> Terrat_change.Dirspaceflow.Workflow.t Terrat_change.Dirspaceflow.t list -> t

      val make_completed_work_manifest : t -> t
      val merge_work_manifest : t -> Event.Pull_request.t Terrat_work_manifest.Existing.t -> t
      val is_work_manifest_runnable : t -> bool

      val to_response :
        t ->
        (Terrat_api_components.Work_manifest.t, [> `Error | `Bad_glob of string ]) result
        Abb.Future.t

      (** Fetch a work manifest if it exists.  If it is in a queued state then
          initiate it. *)
      val initiate_work_manifest :
        request_id:string ->
        work_manifest_id:Uuidm.t ->
        Terrat_config.t ->
        Pgsql_io.t ->
        Terrat_api_components.Work_manifest_initiate.t ->
        (t option, [> `Error ]) result Abb.Future.t

      val query_dirspaces_without_valid_plans :
        Pgsql_io.t -> t -> (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

      val query_dirspaces_owned_by_other_pull_requests :
        Pgsql_io.t ->
        t ->
        (Pull_request.Lite.t Work_manifest.Dirspace_map.t, [> `Error ]) result Abb.Future.t

      val publish_msg_bad_glob : t -> string -> unit Abb.Future.t
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
        has_changes:bool ->
        Terrat_storage.t ->
        Uuidm.t ->
        string ->
        (unit, [> `Error ]) result Abb.Future.t
    end

    module Results : sig
      module Kind : sig
        module Pull_request : sig
          type t
        end

        module Drift : sig
          type t
        end
      end

      type t

      val kind : t -> (Kind.Pull_request.t, Kind.Drift.t) Terrat_work_manifest.Kind.t

      val merge_pull_request :
        t ->
        Kind.Pull_request.t ->
        (unit, [> `Error | `Error_with_msg of string ]) result Abb.Future.t

      val delete_pull_request_branch :
        t -> Kind.Pull_request.t -> (unit, [> `Error ]) result Abb.Future.t

      val query_missing_applied_dirspaces :
        t -> Kind.Pull_request.t -> (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

      val query_drift_schedule :
        t -> Terrat_storage.t -> Kind.Drift.t -> (Drift.Schedule.t, [> `Error ]) result Abb.Future.t

      val fetch_repo_config : t -> (Terrat_repo_config.Version_1.t, [> `Error ]) result Abb.Future.t

      val store_tf_operation :
        request_id:string ->
        Terrat_config.t ->
        Terrat_storage.t ->
        Uuidm.t ->
        Terrat_api_components_work_manifest_tf_operation_result.t ->
        (t, [> `Error ]) result Abb.Future.t

      val store_index :
        request_id:string ->
        Terrat_config.t ->
        Terrat_storage.t ->
        Uuidm.t ->
        Terrat_api_components_work_manifest_index_result.t ->
        (unit, [> `Error ]) result Abb.Future.t

      val publish_msg_automerge :
        t -> Kind.Pull_request.t -> string -> (unit, [> `Error ]) result Abb.Future.t
    end
  end
end

module Make (S : S) : sig
  module Event : sig
    val eval : Terrat_storage.t -> S.Event.T.t -> unit Abb.Future.t
  end

  module Drift : sig
    module Service : sig
      val run : Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
    end

    val run_schedule :
      Terrat_config.t -> Terrat_storage.t -> S.Drift.Schedule.t -> unit Abb.Future.t
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
      has_changes:bool ->
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
