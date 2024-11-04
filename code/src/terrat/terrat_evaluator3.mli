module Unlock_id : sig
  type t =
    | Pull_request of int
    | Drift
  [@@deriving show]
end

module Msg : sig
  type access_control_denied =
    [ `All_dirspaces of Terrat_access_control.R.Deny.t list
    | `Ci_config_update of Terrat_base_repo_config_v1.Access_control.Match_list.t
    | `Dirspaces of Terrat_access_control.R.Deny.t list
    | `Files of string * Terrat_base_repo_config_v1.Access_control.Match_list.t
    | `Lookup_err
    | `Terrateam_config_update of Terrat_base_repo_config_v1.Access_control.Match_list.t
    | `Unlock of Terrat_base_repo_config_v1.Access_control.Match_list.t
    ]

  type ('account, 'pull_request, 'target, 'apply_requirements) t =
    | Access_control_denied of (string * access_control_denied)
    | Account_expired
    | Apply_no_matching_dirspaces
    | Apply_requirements_config_err of [ Terrat_tag_query_ast.err | `Invalid_query of string ]
    | Apply_requirements_validation_err
    | Autoapply_running
    | Bad_custom_branch_tag_pattern of (string * string)
    | Bad_glob of string
    | Build_config_err of Terrat_base_repo_config_v1.of_version_1_err
    | Build_config_failure of string
    | Conflicting_work_manifests of ('account, 'target) Terrat_work_manifest3.Existing.t list
    | Depends_on_cycle of Terrat_dirspace.t list
    | Dest_branch_no_match of 'pull_request
    | Dirspaces_owned_by_other_pull_request of (Terrat_change.Dirspace.t * 'pull_request) list
    | Help
    | Index_complete of (bool * (string * int option * string) list)
    | Invalid_unlock_id of string
    | Maybe_stale_work_manifests of ('account, 'target) Terrat_work_manifest3.Existing.t list
    | Mismatched_refs
    | Missing_plans of Terrat_change.Dirspace.t list
    | Plan_no_matching_dirspaces
    | Pull_request_not_appliable of ('pull_request * 'apply_requirements)
    | Pull_request_not_mergeable
    | Repo_config of (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t)
    | Repo_config_err of Terrat_base_repo_config_v1.of_version_1_err
    | Repo_config_failure of string
    | Repo_config_parse_failure of string * string
    | Run_work_manifest_err of [ `Failed_to_start | `Missing_workflow ]
    | Tag_query_err of Terrat_tag_query_ast.err
    | Tf_op_result of {
        is_layered_run : bool;
        remaining_layers : Terrat_change_match3.Dirspace_config.t list list;
        result : Terrat_api_components_work_manifest_tf_operation_result.t;
        work_manifest : ('account, 'target) Terrat_work_manifest3.Existing.t;
      }
    | Tf_op_result2 of {
        config : Terrat_config.t;
        is_layered_run : bool;
        remaining_layers : Terrat_change_match3.Dirspace_config.t list list;
        result : Terrat_api_components_work_manifest_tf_operation_result2.t;
        work_manifest : ('account, 'target) Terrat_work_manifest3.Existing.t;
      }
    | Unexpected_temporary_err
    | Unlock_success
end

module Ctx : sig
  type 's t

  val make : request_id:string -> config:Terrat_config.t -> storage:'s -> unit -> 's t
  val request_id : 's t -> string
  val config : 's t -> Terrat_config.t
  val storage : 's t -> 's
end

module Work_manifest_result : sig
  type t = {
    dirspaces_success : (Terrat_change.Dirspace.t * bool) list;
    overall_success : bool;
    post_hooks_success : bool;
    pre_hooks_success : bool;
  }
end

module Conflicting_work_manifests : sig
  type 'a t =
    | Conflicting of 'a list
    | Maybe_stale of 'a list
end

module Db = Pgsql_io

module Target : sig
  type ('pr, 'repo) t =
    | Pr of 'pr
    | Drift of {
        repo : 'repo;
        branch : string;
      }
end

module Index : sig
  module Failure : sig
    type t = {
      file : string;
      line_num : int option;
      error : string;
    }
  end

  type t = {
    success : bool;
    failures : Failure.t list;
    index : Terrat_base_repo_config_v1.Index.t;
  }
end

module type S = sig
  module User : sig
    type t [@@deriving yojson]

    val to_string : t -> string
  end

  module Account : sig
    type t [@@deriving eq, yojson]

    val to_string : t -> string
  end

  module Client : sig
    type t
  end

  module Drift : sig
    type t
  end

  module Ref : sig
    type t [@@deriving eq, yojson]

    val to_string : t -> string
    val of_string : string -> t
  end

  module Repo : sig
    type t [@@deriving eq, yojson]

    val owner : t -> string
    val name : t -> string
    val to_string : t -> string
  end

  module Remote_repo : sig
    type t [@@deriving yojson]

    val to_repo : t -> Repo.t
    val default_branch : t -> Ref.t
  end

  module Pull_request : sig
    type stored [@@deriving yojson]
    type fetched [@@deriving yojson]
    type 'a t [@@deriving yojson]

    val base_branch_name : 'a t -> Ref.t
    val base_ref : 'a t -> Ref.t
    val branch_name : 'a t -> Ref.t
    val branch_ref : 'a t -> Ref.t
    val diff : fetched t -> Terrat_change.Diff.t list
    val id : 'a t -> int
    val is_draft_pr : fetched t -> bool
    val provisional_merge_ref : fetched t -> Ref.t option
    val repo : 'a t -> Repo.t
    val state : 'a t -> Terrat_pull_request.State.t
    val stored_of_fetched : fetched t -> stored t
  end

  module Access_control : Terrat_access_control.S

  module Apply_requirements : sig
    type t

    val passed : t -> bool
    val approved_reviews : t -> Terrat_pull_request_review.t list
  end

  val create_client :
    request_id:string -> Terrat_config.t -> Account.t -> (Client.t, [> `Error ]) result Abb.Future.t

  val store_account_repository :
    request_id:string -> Db.t -> Account.t -> Repo.t -> (unit, [> `Error ]) result Abb.Future.t

  val query_account_status :
    request_id:string ->
    Db.t ->
    Account.t ->
    ([ `Active | `Expired | `Disabled ], [> `Error ]) result Abb.Future.t

  val store_pull_request :
    request_id:string ->
    Db.t ->
    Pull_request.fetched Pull_request.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val fetch_branch_sha :
    request_id:string ->
    Client.t ->
    Repo.t ->
    Ref.t ->
    (Ref.t option, [> `Error ]) result Abb.Future.t

  val fetch_file :
    request_id:string ->
    Client.t ->
    Repo.t ->
    Ref.t ->
    string ->
    (string option, [> `Error ]) result Abb.Future.t

  val fetch_remote_repo :
    request_id:string -> Client.t -> Repo.t -> (Remote_repo.t, [> `Error ]) result Abb.Future.t

  val fetch_centralized_repo :
    request_id:string ->
    Client.t ->
    string ->
    (Remote_repo.t option, [> `Error ]) result Abb.Future.t

  val fetch_tree :
    request_id:string ->
    Client.t ->
    Repo.t ->
    Ref.t ->
    (string list, [> `Error ]) result Abb.Future.t

  val query_index :
    request_id:string ->
    Db.t ->
    Account.t ->
    Ref.t ->
    (Index.t option, [> `Error ]) result Abb.Future.t

  val store_index :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    Terrat_api_components.Work_manifest_index_result.t ->
    (Index.t, [> `Error ]) result Abb.Future.t

  val store_index_result :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    Terrat_api_components.Work_manifest_index_result.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val query_repo_config_json :
    request_id:string ->
    Db.t ->
    Account.t ->
    Ref.t ->
    (Yojson.Safe.t option, [> `Error ]) result Abb.Future.t

  val store_repo_config_json :
    request_id:string ->
    Db.t ->
    Account.t ->
    Ref.t ->
    Yojson.Safe.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val cleanup_repo_configs : request_id:string -> Db.t -> (unit, [> `Error ]) result Abb.Future.t

  val publish_msg :
    request_id:string ->
    Client.t ->
    User.t ->
    'a Pull_request.t ->
    (Account.t, 'b Pull_request.t, ('c Pull_request.t, Repo.t) Target.t, Apply_requirements.t) Msg.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val fetch_pull_request :
    request_id:string ->
    Account.t ->
    Client.t ->
    Repo.t ->
    int ->
    (Pull_request.fetched Pull_request.t, [> `Error ]) result Abb.Future.t

  val react_to_comment :
    request_id:string -> Client.t -> Repo.t -> int -> (unit, [> `Error ]) result Abb.Future.t

  val query_next_pending_work_manifest :
    request_id:string ->
    Db.t ->
    ( ( Account.t,
        (Pull_request.stored Pull_request.t, Repo.t) Target.t )
      Terrat_work_manifest3.Existing.t
      option,
      [> `Error ] )
    result
    Abb.Future.t

  val run_work_manifest :
    request_id:string ->
    Terrat_config.t ->
    Client.t ->
    ( Account.t,
      (Pull_request.stored Pull_request.t, Repo.t) Target.t )
    Terrat_work_manifest3.Existing.t ->
    (unit, [> `Failed_to_start | `Missing_workflow | `Error ]) result Abb.Future.t

  val store_flow_state :
    request_id:string -> Db.t -> Uuidm.t -> string -> (unit, [> `Error ]) result Abb.Future.t

  val query_flow_state :
    request_id:string -> Db.t -> Uuidm.t -> (string option, [> `Error ]) result Abb.Future.t

  val delete_flow_state :
    request_id:string -> Db.t -> Uuidm.t -> (unit, [> `Error ]) result Abb.Future.t

  val cleanup_flow_states : request_id:string -> Db.t -> (unit, [> `Error ]) result Abb.Future.t

  val create_work_manifest :
    request_id:string ->
    Db.t ->
    (Account.t, (Pull_request.stored Pull_request.t, Repo.t) Target.t) Terrat_work_manifest3.New.t ->
    ( ( Account.t,
        (Pull_request.stored Pull_request.t, Repo.t) Target.t )
      Terrat_work_manifest3.Existing.t,
      [> `Error ] )
    result
    Abb.Future.t

  val update_work_manifest_state :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    Terrat_work_manifest3.State.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val update_work_manifest_run_id :
    request_id:string -> Db.t -> Uuidm.t -> string -> (unit, [> `Error ]) result Abb.Future.t

  val update_work_manifest_changes :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    int Terrat_change.Dirspaceflow.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val update_work_manifest_denied_dirspaces :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    Terrat_work_manifest3.Deny.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val update_work_manifest_steps :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    Terrat_work_manifest3.Step.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val query_work_manifest :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    ( ( Account.t,
        (Pull_request.stored Pull_request.t, Repo.t) Target.t )
      Terrat_work_manifest3.Existing.t
      option,
      [> `Error ] )
    result
    Abb.Future.t

  val make_commit_check :
    ?work_manifest:('a, 'b) Terrat_work_manifest3.Existing.t ->
    config:Terrat_config.t ->
    description:string ->
    title:string ->
    status:Terrat_commit_check.Status.t ->
    repo:Repo.t ->
    Account.t ->
    Terrat_commit_check.t

  val create_commit_checks :
    request_id:string ->
    Client.t ->
    Repo.t ->
    Ref.t ->
    Terrat_commit_check.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val fetch_commit_checks :
    request_id:string ->
    Client.t ->
    Repo.t ->
    Ref.t ->
    (Terrat_commit_check.t list, [> `Error ]) result Abb.Future.t

  val unlock :
    request_id:string -> Db.t -> Repo.t -> Unlock_id.t -> (unit, [> `Error ]) result Abb.Future.t

  val create_access_control_ctx :
    request_id:string -> Client.t -> Terrat_config.t -> Repo.t -> User.t -> Access_control.Ctx.t

  val query_pull_request_out_of_change_applies :
    request_id:string ->
    Db.t ->
    'a Pull_request.t ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_applied_dirspaces :
    request_id:string ->
    Db.t ->
    'a Pull_request.t ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_dirspaces_without_valid_plans :
    request_id:string ->
    Db.t ->
    'a Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val store_dirspaceflows :
    request_id:string ->
    base_ref:Ref.t ->
    branch_ref:Ref.t ->
    Db.t ->
    Repo.t ->
    Terrat_change.Dirspaceflow.Workflow.t Terrat_change.Dirspaceflow.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val fetch_plan :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    Terrat_dirspace.t ->
    (string option, [> `Error ]) result Abb.Future.t

  val store_plan :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    Terrat_dirspace.t ->
    string ->
    bool ->
    (unit, [> `Error ]) result Abb.Future.t

  val cleanup_plans : request_id:string -> Db.t -> (unit, [> `Error ]) result Abb.Future.t

  val work_manifest_result :
    Terrat_api_components_work_manifest_tf_operation_result.t -> Work_manifest_result.t

  val work_manifest_result2 :
    Terrat_api_components_work_manifest_tf_operation_result2.t -> Work_manifest_result.t

  val store_tf_operation_result :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    Terrat_api_components_work_manifest_tf_operation_result.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val store_tf_operation_result2 :
    request_id:string ->
    Db.t ->
    Uuidm.t ->
    Terrat_api_components_work_manifest_tf_operation_result2.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val query_conflicting_work_manifests_in_repo :
    request_id:string ->
    Db.t ->
    'a Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    [< `Plan | `Apply ] ->
    ( ( Account.t,
        (Pull_request.stored Pull_request.t, Repo.t) Target.t )
      Terrat_work_manifest3.Existing.t
      Conflicting_work_manifests.t
      option,
      [> `Error ] )
    result
    Abb.Future.t

  val eval_apply_requirements :
    request_id:string ->
    Terrat_config.t ->
    User.t ->
    Client.t ->
    'a Terrat_base_repo_config_v1.t ->
    Pull_request.fetched Pull_request.t ->
    Terrat_change_match3.Dirspace_config.t list ->
    (Apply_requirements.t, [> `Error ]) result Abb.Future.t

  val query_dirspaces_owned_by_other_pull_requests :
    request_id:string ->
    Db.t ->
    'a Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    ((Terrat_change.Dirspace.t * Pull_request.stored Pull_request.t) list, [> `Error ]) result
    Abb.Future.t

  val merge_pull_request :
    request_id:string -> Client.t -> 'a Pull_request.t -> (unit, [> `Error ]) result Abb.Future.t

  val delete_pull_request_branch :
    request_id:string -> Client.t -> 'a Pull_request.t -> (unit, [> `Error ]) result Abb.Future.t

  val store_drift_schedule :
    request_id:string ->
    Db.t ->
    Repo.t ->
    Terrat_base_repo_config_v1.Drift.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val query_missing_drift_scheduled_runs :
    request_id:string -> Db.t -> ((Account.t * Repo.t) list, [> `Error ]) result Abb.Future.t

  val repo_config_of_json :
    Yojson.Safe.t ->
    ( Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t,
      [> Terrat_base_repo_config_v1.of_version_1_err | `Repo_config_parse_err of string ] )
    result
    Abb.Future.t

  val fetch_repo_config_with_provenance :
    ?system_defaults:Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t ->
    ?built_config:Yojson.Safe.t ->
    string ->
    Client.t ->
    Repo.t ->
    Ref.t ->
    ( string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t,
      [> Terratc_intf.Repo_config.fetch_err ] )
    result
    Abb.Future.t
end

module Make (S : S) : sig
  module Repo_config : sig
    type fetch_err =
      [ Terrat_base_repo_config_v1.of_version_1_err
      | `Repo_config_parse_err of string * string
      | Jsonu.merge_err
      | `Json_decode_err of string * string
      | `Unexpected_err of string
      | `Yaml_decode_err of string * string
      | `Error
      ]
    [@@deriving show]
  end

  module State : Abb_flow.S
  module Id : Abb_flow.ID

  module Event : sig
    type t =
      | Pull_request_open of {
          account : S.Account.t;
          user : S.User.t;
          repo : S.Repo.t;
          pull_request_id : int;
        }
      | Pull_request_close of {
          account : S.Account.t;
          user : S.User.t;
          repo : S.Repo.t;
          pull_request_id : int;
        }
      | Pull_request_sync of {
          account : S.Account.t;
          user : S.User.t;
          repo : S.Repo.t;
          pull_request_id : int;
        }
      | Pull_request_ready_for_review of {
          account : S.Account.t;
          user : S.User.t;
          repo : S.Repo.t;
          pull_request_id : int;
        }
      | Pull_request_comment of {
          account : S.Account.t;
          comment : Terrat_comment.t;
          repo : S.Repo.t;
          pull_request_id : int;
          comment_id : int;
          user : S.User.t;
        }
      | Push of {
          account : S.Account.t;
          user : S.User.t;
          repo : S.Repo.t;
          branch : S.Ref.t;
        }
      | Run_scheduled_drift
      | Run_drift of {
          account : S.Account.t;
          repo : S.Repo.t;
        }
  end

  module Flow : module type of Abb_flow.Make (Abb.Future) (Id) (State)

  val run_event : Terrat_storage.t Ctx.t -> Event.t -> unit Abb.Future.t

  val run_work_manifest_initiate :
    Terrat_storage.t Ctx.t ->
    Cstruct.t ->
    Uuidm.t ->
    Terrat_api_components.Work_manifest_initiate.t ->
    (Terrat_api_components.Work_manifest.t option, [> `Error ]) result Abb.Future.t

  val run_work_manifest_result :
    Terrat_storage.t Ctx.t ->
    Uuidm.t ->
    Terrat_api_components.Work_manifest_result.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val run_plan_store :
    Terrat_storage.t Ctx.t ->
    Uuidm.t ->
    Terrat_api_components.Plan_create.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val run_plan_fetch :
    Terrat_storage.t Ctx.t ->
    Uuidm.t ->
    Terrat_dirspace.t ->
    (string option, [> `Error ]) result Abb.Future.t

  (** Signal that the work manifest failed for OOB reasons. *)
  val run_work_manifest_failure :
    Terrat_storage.t Ctx.t -> Uuidm.t -> (unit, [> `Error ]) result Abb.Future.t

  val run_scheduled_drift : Terrat_storage.t Ctx.t -> (unit, [> `Error ]) result Abb.Future.t
  val run_plan_cleanup : Terrat_storage.t Ctx.t -> (unit, [> `Error ]) result Abb.Future.t
  val run_flow_state_cleanup : Terrat_storage.t Ctx.t -> (unit, [> `Error ]) result Abb.Future.t
  val run_repo_config_cleanup : Terrat_storage.t Ctx.t -> (unit, [> `Error ]) result Abb.Future.t
end
