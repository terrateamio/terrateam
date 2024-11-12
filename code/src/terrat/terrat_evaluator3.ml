let result_version = 2

module Metrics = struct
  module DefaultHistogram = Prmths.DefaultHistogram

  module Dirspaces_per_work_manifest_histogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_list [ 1.0; 5.0; 10.0; 20.0; 50.0; 100.0 ]
  end)

  let namespace = "terrat"
  let subsystem = "evaluator"

  let op_on_account_disabled_total =
    let help = "Count of operations on a disabled account" in
    Prmths.Counter.v ~help ~namespace ~subsystem "op_on_account_disabled_total"

  let access_control_total =
    let help = "Count of access control calls" in
    let family =
      Prmths.Counter.v_labels
        ~label_names:[ "type"; "result" ]
        ~help
        ~namespace
        ~subsystem
        "access_control_total"
    in
    fun ~t ~r -> Prmths.Counter.labels family [ t; r ]
end

module Unlock_id = struct
  type t =
    | Pull_request of int
    | Drift
  [@@deriving show]

  let to_string = function
    | Pull_request id -> CCInt.to_string id
    | Drift -> "drift"
end

module Msg = struct
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

module Ctx = struct
  type 's t = {
    request_id : string;
    config : Terrat_config.t;
    storage : 's;
  }

  let make ~request_id ~config ~storage () = { request_id; config; storage }
  let request_id t = t.request_id
  let config t = t.config
  let storage t = t.storage
end

module Work_manifest_result = struct
  type t = {
    dirspaces_success : (Terrat_change.Dirspace.t * bool) list;
    overall_success : bool;
    post_hooks_success : bool;
    pre_hooks_success : bool;
  }
end

module Conflicting_work_manifests = struct
  type 'a t =
    | Conflicting of 'a list
    | Maybe_stale of 'a list
end

module Comment = struct
  let to_yojson = CCFun.(Terrat_comment.to_string %> [%to_yojson: string])

  let of_yojson json =
    let open CCResult.Infix in
    [%of_yojson: string] json
    >>= fun comment -> CCResult.map_err Terrat_comment.show_err (Terrat_comment.parse comment)
end

module Db = Pgsql_io

module Target = struct
  type ('pr, 'repo) t =
    | Pr of 'pr
    | Drift of {
        repo : 'repo;
        branch : string;
      }
end

module Index = struct
  module Failure = struct
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

module Make (S : S) = struct
  (* Logging wrappers *)
  let log_time ?m request_id name t =
    Logs.info (fun m -> m "EVALUATOR : %s : %s : time=%f" request_id name t);
    match m with
    | Some m -> Metrics.DefaultHistogram.observe m t
    | None -> ()

  let create_client request_id config account =
    Abbs_time_it.run (log_time request_id "CREATE_CLIENT") (fun () ->
        S.create_client ~request_id config account)

  let store_account_repository request_id db account repo =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : STORE_ACCOUNT_REPOSITORY : account=%s : repo=%s : time=%f"
              request_id
              (S.Account.to_string account)
              (S.Repo.to_string repo)
              time))
      (fun () -> S.store_account_repository ~request_id db account repo)

  let query_account_status request_id db account =
    Abbs_time_it.run (log_time request_id "QUERY_ACCOUNT_STATE") (fun () ->
        S.query_account_status ~request_id db account)

  let store_pull_request request_id db pull_request =
    Abbs_time_it.run (log_time request_id "STORE_PULL_REQUEST") (fun () ->
        S.store_pull_request ~request_id db pull_request)

  let fetch_branch_sha request_id client repo ref_ =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FETCH_BRANCH_SHA : repo=%s : ref_=%s : time=%f"
              request_id
              (S.Repo.to_string repo)
              (S.Ref.to_string ref_)
              time))
      (fun () -> S.fetch_branch_sha ~request_id client repo ref_)

  let fetch_file request_id client repo ref_ path =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FETCH_FILE : repo=%s : ref=%s : path=%s : time=%f"
              request_id
              (S.Repo.to_string repo)
              (S.Ref.to_string ref_)
              path
              time))
      (fun () -> S.fetch_file ~request_id client repo ref_ path)

  let fetch_remote_repo request_id client repo =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FETCH_REMOTE_REPO : repo=%s : time=%f"
              request_id
              (S.Repo.to_string repo)
              time))
      (fun () -> S.fetch_remote_repo ~request_id client repo)

  let fetch_centralized_repo request_id client owner =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m "EVALUATOR : %s : FETCH_CENTRALIZED_REPO : owner=%s : time=%f" request_id owner time))
      (fun () -> S.fetch_centralized_repo ~request_id client owner)

  let fetch_tree request_id client repo ref_ =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FETCH_TREE : repo=%s : ref=%s : time=%f"
              request_id
              (S.Repo.to_string repo)
              (S.Ref.to_string ref_)
              time))
      (fun () -> S.fetch_tree ~request_id client repo ref_)

  let query_index request_id db account ref_ =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : QUERY_INDEX : ref=%s : time=%f"
              request_id
              (S.Ref.to_string ref_)
              time))
      (fun () -> S.query_index ~request_id db account ref_)

  let store_index request_id db work_manifest_id index =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : STORE_INDEX : id=%a : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              time))
      (fun () -> S.store_index ~request_id db work_manifest_id index)

  let store_index_result request_id db work_manifest_id result =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : STORE_INDEX_RESULT : id=%a : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              time))
      (fun () -> S.store_index_result ~request_id db work_manifest_id result)

  let query_repo_config_json request_id db account ref_ =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : QUERY_REPO_CONFIG : account=%s : ref=%s : time=%f"
              request_id
              (S.Account.to_string account)
              (S.Ref.to_string ref_)
              time))
      (fun () -> S.query_repo_config_json ~request_id db account ref_)

  let store_repo_config_json request_id db account ref_ repo_config =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : STORE_REPO_CONFIG : account=%s : ref=%s : time=%f"
              request_id
              (S.Account.to_string account)
              (S.Ref.to_string ref_)
              time))
      (fun () -> S.store_repo_config_json ~request_id db account ref_ repo_config)

  let cleanup_repo_configs request_id db =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m -> m "EVALUATOR : %s : CLEANUP_REPO_CONFIGS : time=%f" request_id time))
      (fun () -> S.cleanup_repo_configs ~request_id db)

  let publish_msg request_id client user pull_request msg =
    Abbs_time_it.run
      (fun time -> Logs.info (fun m -> m "EVALUATOR : %s : PUBLISH_MSG : time=%f" request_id time))
      (fun () -> S.publish_msg ~request_id client user pull_request msg)

  let fetch_pull_request request_id account client repo pull_request_id =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FETCH_PULL_REQUEST : repo=%s : pull_request_id=%d : time=%f"
              request_id
              (S.Repo.to_string repo)
              pull_request_id
              time))
      (fun () -> S.fetch_pull_request ~request_id account client repo pull_request_id)

  let react_to_comment request_id client repo comment_id =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : REACT_TO_COMMENT : repo=%s : comment_id=%d : time=%f"
              request_id
              (S.Repo.to_string repo)
              comment_id
              time))
      (fun () -> S.react_to_comment ~request_id client repo comment_id)

  let query_next_pending_work_manifest request_id db =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m "EVALUATOR : %s : QUERY_NEXT_PENDING_WORK_MANIFEST : time=%f" request_id time))
      (fun () -> S.query_next_pending_work_manifest ~request_id db)

  let run_work_manifest request_id config client work_manifest =
    let module Wm = Terrat_work_manifest3 in
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : RUN_WORK_MANIFEST : id=%a : time=%f"
              request_id
              Uuidm.pp
              work_manifest.Wm.id
              time))
      (fun () -> S.run_work_manifest ~request_id config client work_manifest)

  let store_flow_state request_id db work_manifest_id state =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : STORE_FLOW_STATE : id=%a : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              time))
      (fun () -> S.store_flow_state ~request_id db work_manifest_id state)

  let query_flow_state request_id db work_manifest_id =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : QUERY_FLOW_STATE : id=%a : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              time))
      (fun () -> S.query_flow_state ~request_id db work_manifest_id)

  let delete_flow_state request_id db work_manifest_id =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : DELETE_FLOW_STATE : id=%a : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              time))
      (fun () -> S.delete_flow_state ~request_id db work_manifest_id)

  let cleanup_flow_states request_id db =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m -> m "EVALUATOR : %s : CLEANUP_FLOW_STATE : time=%f" request_id time))
      (fun () -> S.cleanup_flow_states ~request_id db)

  let create_work_manifest request_id db work_manifest =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m -> m "EVALUATOR : %s : CREATE_WORK_MANIFEST : time=%f" request_id time))
      (fun () -> S.create_work_manifest ~request_id db work_manifest)

  let update_work_manifest_state request_id db work_manifest_id state =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : UPDATE_WORK_MANIFEST_STATE : id=%a : state=%s : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              (Terrat_work_manifest3.State.to_string state)
              time))
      (fun () -> S.update_work_manifest_state ~request_id db work_manifest_id state)

  let update_work_manifest_run_id request_id db work_manifest_id run_id =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : UPDATE_WORK_MANIFEST_RUN_ID : id=%a : run_id=%s : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              run_id
              time))
      (fun () -> S.update_work_manifest_run_id ~request_id db work_manifest_id run_id)

  let update_work_manifest_changes request_id db work_manifest_id changes =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : UPDATE_WORK_MANIFEST_CHANGES : id=%a : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              time))
      (fun () -> S.update_work_manifest_changes ~request_id db work_manifest_id changes)

  let update_work_manifest_denied_dirspaces request_id db work_manifest_id denied_dirspaces =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : UPDATE_WORK_MANIFEST_DENIED_DIRSPACES : id=%a : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              time))
      (fun () ->
        S.update_work_manifest_denied_dirspaces ~request_id db work_manifest_id denied_dirspaces)

  let update_work_manifest_steps request_id db work_manifest_id steps =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : UPDATE_WORK_MANIFEST_STEPS : id=%a : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              time))
      (fun () -> S.update_work_manifest_steps ~request_id db work_manifest_id steps)

  let query_work_manifest request_id db work_manifest_id =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : QUERY_WORK_MANIFEST : id=%a : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              time))
      (fun () -> S.query_work_manifest ~request_id db work_manifest_id)

  let create_commit_checks request_id client repo ref_ checks =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : CREATE_COMMIT_CHECKS : repo=%s : num=%d : ref=%s : time=%f"
              request_id
              (S.Repo.to_string repo)
              (CCList.length checks)
              (S.Ref.to_string ref_)
              time))
      (fun () -> S.create_commit_checks ~request_id client repo ref_ checks)

  let fetch_commit_checks request_id client repo ref_ =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FETCH_COMMIT_CHECKS : repo=%s : ref=%s : time=%f"
              request_id
              (S.Repo.to_string repo)
              (S.Ref.to_string ref_)
              time))
      (fun () -> S.fetch_commit_checks ~request_id client repo ref_)

  let unlock request_id db repo unlock_id =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : UNLOCK : repo=%s : unlock_id=%s : time=%f"
              request_id
              (S.Repo.to_string repo)
              (Unlock_id.to_string unlock_id)
              time))
      (fun () -> S.unlock ~request_id db repo unlock_id)

  let query_pull_request_out_of_change_applies request_id db pull_request =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : QUERY_PULL_REQUEST_OUT_OF_CHANGE_APPLIES : pull_number=%d : time=%f"
              request_id
              (S.Pull_request.id pull_request)
              time))
      (fun () -> S.query_pull_request_out_of_change_applies ~request_id db pull_request)

  let query_applied_dirspaces request_id db pull_request =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : QUERY_APPLIED_DIRSPACES : pull_number=%d : time=%f"
              request_id
              (S.Pull_request.id pull_request)
              time))
      (fun () -> S.query_applied_dirspaces ~request_id db pull_request)

  let query_dirspaces_without_valid_plans request_id db pull_request dirspaces =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : QUERY_DIRSPACES_WITHOUT_VALID_PLANS : pull_number=%d : time=%f"
              request_id
              (S.Pull_request.id pull_request)
              time))
      (fun () -> S.query_dirspaces_without_valid_plans ~request_id db pull_request dirspaces)

  let store_dirspaceflows ~base_ref ~branch_ref request_id db repo dirspaceflows =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : STORE_DIRSPACEFLOWS : repo=%s : base_ref=%s : branch_ref=%s : \
               time=%f"
              request_id
              (S.Repo.to_string repo)
              (S.Ref.to_string base_ref)
              (S.Ref.to_string branch_ref)
              time))
      (fun () -> S.store_dirspaceflows ~request_id ~base_ref ~branch_ref db repo dirspaceflows)

  let fetch_plan request_id db work_manifest_id dirspace =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FETCH_PLAN : id=%a : dir=%s : workspace=%s : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              dirspace.Terrat_dirspace.dir
              dirspace.Terrat_dirspace.workspace
              time))
      (fun () -> S.fetch_plan ~request_id db work_manifest_id dirspace)

  let cleanup_plans request_id db =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m -> m "EVALUATOR : %s : CLEANUP_PLANS : time=%f" request_id time))
      (fun () -> S.cleanup_plans ~request_id db)

  let store_plan request_id db work_manifest_id dirspace data has_changes =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : STORE_PLAN : id=%a : dir=%s : workspace=%s : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              dirspace.Terrat_dirspace.dir
              dirspace.Terrat_dirspace.workspace
              time))
      (fun () -> S.store_plan ~request_id db work_manifest_id dirspace data has_changes)

  let store_tf_operation_result request_id db work_manifest_id result =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : STORE_TF_OPERATION_RESULT : id=%a : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              time))
      (fun () -> S.store_tf_operation_result ~request_id db work_manifest_id result)

  let store_tf_operation_result2 request_id db work_manifest_id result =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : STORE_TF_OPERATION_RESULT2 : id=%a : time=%f"
              request_id
              Uuidm.pp
              work_manifest_id
              time))
      (fun () -> S.store_tf_operation_result2 ~request_id db work_manifest_id result)

  let query_conflicting_work_manifests_in_repo request_id db pull_request dirspaces op =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m "EVALUATOR : %s : QUERY_CONFLICTING_WORK_MANIFESTS_IN_REPO : time=%f" request_id time))
      (fun () ->
        S.query_conflicting_work_manifests_in_repo ~request_id db pull_request dirspaces op)

  let eval_apply_requirements request_id config user client repo_config pull_request matches =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m -> m "EVALUATOR : %s : EVAL_APPLY_REQUIREMENTS : time=%f" request_id time))
      (fun () ->
        S.eval_apply_requirements ~request_id config user client repo_config pull_request matches)

  let query_dirspaces_owned_by_other_pull_requests request_id db pull_request dirspaces =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : QUERY_DIRSPACES_OWNED_BY_OTHER_PULL_REQUESTS : time=%f"
              request_id
              time))
      (fun () ->
        S.query_dirspaces_owned_by_other_pull_requests ~request_id db pull_request dirspaces)

  let merge_pull_request request_id client pull_request =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m -> m "EVALUATOR : %s : MERGE_PULL_REQUEST : time=%f" request_id time))
      (fun () -> S.merge_pull_request ~request_id client pull_request)

  let delete_pull_request_branch request_id client pull_request =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m "EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : time=%f" request_id time))
      (fun () -> S.delete_pull_request_branch ~request_id client pull_request)

  let store_drift_schedule request_id db repo drift =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : STORE_DRIFT_SCHEDULE : repo=%s : time=%f"
              request_id
              (S.Repo.to_string repo)
              time))
      (fun () -> S.store_drift_schedule ~request_id db repo drift)

  let query_missing_drift_scheduled_runs request_id db =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m "EVALUATOR : %s : QUERY_MISSING_DRIFT_SCHEDULED_RUNS : time=%f" request_id time))
      (fun () -> S.query_missing_drift_scheduled_runs ~request_id db)

  let fetch_repo_config_with_provenance ?built_config ~system_defaults request_id client repo ref_ =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FETCH_REPO_CONFIG_WITH_PROVENANCE : repo=%s : ref=%s : time=%f"
              request_id
              (S.Repo.to_string repo)
              (S.Ref.to_string ref_)
              time))
      (fun () ->
        S.fetch_repo_config_with_provenance
          ?built_config
          ~system_defaults
          request_id
          client
          repo
          ref_)

  module Repo_config = struct
    type fetch_err = Terratc_intf.Repo_config.fetch_err [@@deriving show]

    let repo_config_of_json = S.repo_config_of_json

    let fetch_with_provenance ?built_config ~system_defaults request_id config client repo ref_ =
      fetch_repo_config_with_provenance ?built_config ~system_defaults request_id client repo ref_

    let fetch ?built_config ~system_defaults request_id config client repo ref_ =
      let open Abbs_future_combinators.Infix_result_monad in
      fetch_with_provenance ?built_config ~system_defaults request_id config client repo ref_
      >>= fun (_, repo_config) -> Abb.Future.return (Ok repo_config)
  end

  module Event = struct
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
          comment : Terrat_comment.t; [@to_yojson Comment.to_yojson] [@of_yojson Comment.of_yojson]
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
    [@@deriving yojson]

    let account = function
      | Pull_request_open { account; _ }
      | Pull_request_close { account; _ }
      | Pull_request_sync { account; _ }
      | Pull_request_ready_for_review { account; _ }
      | Pull_request_comment { account; _ }
      | Push { account; _ }
      | Run_drift { account; _ } -> account
      | Run_scheduled_drift -> assert false

    let user = function
      | Pull_request_open { user; _ }
      | Pull_request_close { user; _ }
      | Pull_request_sync { user; _ }
      | Pull_request_ready_for_review { user; _ }
      | Pull_request_comment { user; _ }
      | Push { user; _ } -> user
      | Run_scheduled_drift | Run_drift _ -> assert false

    let initiator = function
      | Pull_request_open { user; _ }
      | Pull_request_close { user; _ }
      | Pull_request_sync { user; _ }
      | Pull_request_ready_for_review { user; _ }
      | Pull_request_comment { user; _ }
      | Push { user; _ } -> Terrat_work_manifest3.Initiator.User (S.User.to_string user)
      | Run_scheduled_drift | Run_drift _ -> Terrat_work_manifest3.Initiator.System

    let repo = function
      | Pull_request_open { repo; _ }
      | Pull_request_close { repo; _ }
      | Pull_request_sync { repo; _ }
      | Pull_request_ready_for_review { repo; _ }
      | Pull_request_comment { repo; _ }
      | Push { repo; _ }
      | Run_drift { repo; _ } -> repo
      | Run_scheduled_drift -> assert false

    let pull_request_id_safe = function
      | Pull_request_open { pull_request_id; _ }
      | Pull_request_close { pull_request_id; _ }
      | Pull_request_sync { pull_request_id; _ }
      | Pull_request_ready_for_review { pull_request_id; _ }
      | Pull_request_comment { pull_request_id; _ } -> Some pull_request_id
      | Push _ | Run_scheduled_drift | Run_drift _ -> None

    let pull_request_id event =
      match pull_request_id_safe event with
      | Some pull_request_id -> pull_request_id
      | None -> assert false

    let unlock_ids = function
      | Pull_request_comment { comment = Terrat_comment.Unlock ids; _ } ->
          CCList.sort_uniq ~cmp:CCString.compare ids
      | Pull_request_open _
      | Pull_request_close _
      | Pull_request_sync _
      | Pull_request_ready_for_review _
      | Pull_request_comment _
      | Push _
      | Run_scheduled_drift
      | Run_drift _ -> assert false

    let trigger_type = function
      | Pull_request_open _
      | Pull_request_sync _
      | Pull_request_ready_for_review _
      | Pull_request_close _ -> `Auto
      | Pull_request_comment _ -> `Manual
      | Push _ | Run_scheduled_drift | Run_drift _ -> assert false
  end

  module Id = struct
    type t =
      | Account_disabled
      | Account_enabled
      | Account_expired
      | Always_store_pull_request
      | Check_access_control_apply
      | Check_access_control_ci_change
      | Check_access_control_files
      | Check_access_control_plan
      | Check_access_control_repo_config
      | Check_account_status_expired
      | Check_all_dirspaces_applied
      | Check_conflicting_work_manifests
      | Check_dirspaces_missing_plans
      | Check_dirspaces_owned_by_other_pull_requests
      | Check_enabled_in_repo_config
      | Check_merge_conflict
      | Check_non_empty_matches
      | Check_pull_request_state
      | Check_reconcile
      | Check_valid_destination_branch
      | Complete_work_manifest
      | Config_build_not_required
      | Config_build_required
      | Create_drift_events
      | Create_work_manifest
      | Event_kind_feedback
      | Event_kind_help
      | Event_kind_index
      | Event_kind_op
      | Event_kind_push
      | Event_kind_repo_config
      | Event_kind_run_drift
      | Event_kind_unlock
      | Index_not_required
      | Index_required
      | Op_kind_apply
      | Op_kind_apply_autoapprove
      | Op_kind_apply_force
      | Op_kind_plan
      | Publish_help
      | Publish_index
      | Publish_repo_config
      | Publish_unlock
      | React_to_comment
      | Record_feedback
      | Recover
      | Recover_noop
      | Run_work_manifest_iter
      | Store_account_repository
      | Store_pull_request
      | Test_account_status
      | Test_config_build_required
      | Test_event_kind
      | Test_index_required
      | Test_op_kind
      | Unlock
      | Unset_work_manifest_id
      | Update_drift_schedule
      | Wait_for_work_manifest_run
    [@@deriving show, eq]

    let to_string = function
      | Account_disabled -> "account_disabled"
      | Account_enabled -> "account_enabled"
      | Account_expired -> "account_expired"
      | Always_store_pull_request -> "always_store_pull_request"
      | Check_access_control_apply -> "check_access_control_apply"
      | Check_access_control_ci_change -> "check_access_control_ci_change"
      | Check_access_control_files -> "check_access_control_files"
      | Check_access_control_plan -> "check_access_control_plan"
      | Check_access_control_repo_config -> "check_access_control_repo_config"
      | Check_account_status_expired -> "check_account_status_expired"
      | Check_all_dirspaces_applied -> "check_all_dirspaces_applied"
      | Check_conflicting_work_manifests -> "check_conflicting_work_manifests"
      | Check_dirspaces_missing_plans -> "check_dirspaces_missing_plans"
      | Check_dirspaces_owned_by_other_pull_requests ->
          "check_dirspaces_owned_by_other_pull_requests"
      | Check_enabled_in_repo_config -> "check_enabled_in_repo_config"
      | Check_merge_conflict -> "check_merge_conflict"
      | Check_non_empty_matches -> "check_non_empty_matches"
      | Check_pull_request_state -> "check_pull_request_state"
      | Check_reconcile -> "check_reconcile"
      | Check_valid_destination_branch -> "check_valid_destination_branch"
      | Complete_work_manifest -> "complete_work_manifest"
      | Config_build_not_required -> "config_build_required"
      | Config_build_required -> "config_build_not_required"
      | Create_drift_events -> "create_drift_events"
      | Create_work_manifest -> "create_work_manifest"
      | Event_kind_feedback -> "event_kind_feedback"
      | Event_kind_help -> "event_kind_help"
      | Event_kind_index -> "event_kind_index"
      | Event_kind_op -> "event_kind_op"
      | Event_kind_push -> "event_kind_push"
      | Event_kind_repo_config -> "event_kind_repo_config"
      | Event_kind_run_drift -> "event_kind_run_drift"
      | Event_kind_unlock -> "event_kind_unlock"
      | Index_not_required -> "index_not_required"
      | Index_required -> "index_required"
      | Op_kind_apply -> "op_kind_apply"
      | Op_kind_apply_autoapprove -> "op_kind_apply_autoapprove"
      | Op_kind_apply_force -> "op_kind_apply_force"
      | Op_kind_plan -> "op_kind_plan"
      | Publish_help -> "publish_help"
      | Publish_index -> "publish_index"
      | Publish_repo_config -> "publish_repo_config"
      | Publish_unlock -> "publish_unlock"
      | React_to_comment -> "react_to_comment"
      | Record_feedback -> "record_feedback"
      | Recover -> "recover"
      | Recover_noop -> "recover_noop"
      | Run_work_manifest_iter -> "run_work_manifest_iter"
      | Store_account_repository -> "store_account_repository"
      | Store_pull_request -> "store_pull_request"
      | Test_account_status -> "test_account_status"
      | Test_config_build_required -> "test_config_build_required"
      | Test_event_kind -> "test_event_kind"
      | Test_index_required -> "test_index_required"
      | Test_op_kind -> "test_op_kind"
      | Unlock -> "unlock"
      | Unset_work_manifest_id -> "unset_work_manifest_id"
      | Update_drift_schedule -> "update_drift_schedule"
      | Wait_for_work_manifest_run -> "wait_for_work_manifest_run"

    let of_string = function
      | "account_disabled" -> Some Account_disabled
      | "account_enabled" -> Some Account_enabled
      | "account_expired" -> Some Account_expired
      | "always_store_pull_request" -> Some Always_store_pull_request
      | "check_access_control_apply" -> Some Check_access_control_apply
      | "check_access_control_ci_change" -> Some Check_access_control_ci_change
      | "check_access_control_files" -> Some Check_access_control_files
      | "check_access_control_plan" -> Some Check_access_control_plan
      | "check_access_control_repo_config" -> Some Check_access_control_repo_config
      | "check_account_status_expired" -> Some Check_account_status_expired
      | "check_all_dirspaces_applied" -> Some Check_all_dirspaces_applied
      | "check_conflicting_work_manifests" -> Some Check_conflicting_work_manifests
      | "check_dirspaces_missing_plans" -> Some Check_dirspaces_missing_plans
      | "check_dirspaces_owned_by_other_pull_requests" ->
          Some Check_dirspaces_owned_by_other_pull_requests
      | "check_enabled_in_repo_config" -> Some Check_enabled_in_repo_config
      | "check_merge_conflict" -> Some Check_merge_conflict
      | "check_non_empty_matches" -> Some Check_non_empty_matches
      | "check_pull_request_state" -> Some Check_pull_request_state
      | "check_reconcile" -> Some Check_reconcile
      | "check_valid_destination_branch" -> Some Check_valid_destination_branch
      | "complete_work_manifest" -> Some Complete_work_manifest
      | "config_build_required" -> Some Config_build_not_required
      | "config_build_not_required" -> Some Config_build_required
      | "create_drift_events" -> Some Create_drift_events
      | "create_work_manifest" -> Some Create_work_manifest
      | "event_kind_feedback" -> Some Event_kind_feedback
      | "event_kind_help" -> Some Event_kind_help
      | "event_kind_index" -> Some Event_kind_index
      | "event_kind_op" -> Some Event_kind_op
      | "event_kind_push" -> Some Event_kind_push
      | "event_kind_repo_config" -> Some Event_kind_repo_config
      | "event_kind_run_drift" -> Some Event_kind_run_drift
      | "event_kind_unlock" -> Some Event_kind_unlock
      | "index_not_required" -> Some Index_not_required
      | "index_required" -> Some Index_required
      | "op_kind_apply" -> Some Op_kind_apply
      | "op_kind_apply_autoapprove" -> Some Op_kind_apply_autoapprove
      | "op_kind_apply_force" -> Some Op_kind_apply_force
      | "op_kind_plan" -> Some Op_kind_plan
      | "publish_help" -> Some Publish_help
      | "publish_index" -> Some Publish_index
      | "publish_repo_config" -> Some Publish_repo_config
      | "publish_unlock" -> Some Publish_unlock
      | "react_to_comment" -> Some React_to_comment
      | "record_feedback" -> Some Record_feedback
      | "recover" -> Some Recover
      | "recover_noop" -> Some Recover_noop
      | "run_work_manifest_iter" -> Some Run_work_manifest_iter
      | "store_account_repository" -> Some Store_account_repository
      | "store_pull_request" -> Some Store_pull_request
      | "test_account_status" -> Some Test_account_status
      | "test_config_build_required" -> Some Test_config_build_required
      | "test_event_kind" -> Some Test_event_kind
      | "test_index_required" -> Some Test_index_required
      | "test_op_kind" -> Some Test_op_kind
      | "unlock" -> Some Unlock
      | "unset_work_manifest_id" -> Some Unset_work_manifest_id
      | "update_drift_schedule" -> Some Update_drift_schedule
      | "wait_for_work_manifest_run" -> Some Wait_for_work_manifest_run
      | _ -> None
  end

  module State = struct
    type of_string_err = [ `Error ] [@@deriving show]

    module St = struct
      type t =
        | Initial
        | Resume
        | Waiting_for_work_manifest_run
        | Waiting_for_work_manifest_initiate
        | Waiting_for_work_manifest_result
        | Work_manifest_completed
      [@@deriving show, yojson]
    end

    module Io = struct
      module I = struct
        type t =
          | Work_manifest_initiate of {
              encryption_key : Cstruct.t;
              initiate : Terrat_api_components.Work_manifest_initiate.t;
              p :
                (Terrat_api_components.Work_manifest.t option, [ `Error ]) result
                Abb.Future.Promise.t;
            }
          | Work_manifest_result of {
              result : Terrat_api_components.Work_manifest_result.t;
              p : (unit, [ `Error ]) result Abb.Future.Promise.t;
            }
          | Work_manifest_run_success
          | Work_manifest_run_failure of [ `Failed_to_start | `Missing_workflow | `Error ]
          | Plan_store of {
              dirspace : Terrat_dirspace.t;
              data : string;
              has_changes : bool;
              p : (unit, [ `Error ]) result Abb.Future.Promise.t;
            }
          | Plan_fetch of {
              dirspace : Terrat_dirspace.t;
              p : (string option, [ `Error ]) result Abb.Future.Promise.t;
            }
          | Work_manifest_failure of { p : (unit, [ `Error ]) result Abb.Future.Promise.t }
          | Checkpointed
      end

      module O = struct
        type 'a t =
          | Clone of 'a list
          | Checkpoint
      end
    end

    type uuidm = Uuidm.t

    let uuidm_to_yojson = CCFun.(Uuidm.to_string %> [%to_yojson: string])

    let uuidm_of_yojson json =
      let open CCResult.Infix in
      [%of_yojson: string] json
      >>= fun uuid ->
      CCResult.map_err
        (CCFun.const ("Invalid uuid: " ^ uuid))
        (CCResult.of_opt (Uuidm.of_string uuid))

    type t = {
      event : Event.t;
      request_id : string;
      work_manifest_id : uuidm option;
      st : St.t;
      input : Io.I.t option; [@to_yojson fun _ -> `Null] [@of_yojson fun _ -> Ok None]
      output : t Io.O.t option; [@to_yojson fun _ -> `Null] [@of_yojson fun _ -> Ok None]
    }
    [@@deriving yojson]

    type step_err =
      [ `Error
      | Repo_config.fetch_err
      | `Noop of (t[@opaque])
      ]
    [@@deriving show]

    let to_string t = Yojson.Safe.to_string (to_yojson t)

    let of_string s =
      try CCResult.map_err (fun _ -> `Error) (of_yojson (Yojson.Safe.from_string s))
      with Yojson.Json_error _ -> Error `Error
  end

  module Flow = Abb_flow.Make (Abb.Future) (Id) (State)

  let log = function
    | Flow.Event.Step_start (step, state) ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FLOW : STEP_START : %s"
              state.State.request_id
              (Id.to_string (Flow.Step.id step)))
    | Flow.Event.Step_end (step, ret, state) ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FLOW : STEP_END : %s : %s"
              state.State.request_id
              (Id.to_string (Flow.Step.id step))
              (match ret with
              | `Failure (`Step_err (_, `Noop _)) -> "NOOP"
              | `Failure run_err -> "FAILURE : " ^ Flow.show_run_err run_err
              | `Success _ -> "SUCCESS"
              | `Yield state -> (
                  match state.State.output with
                  | Some State.Io.O.Checkpoint -> "CHECKPOINT"
                  | _ -> "YIELD")))
    | Flow.Event.Choice_start (id, state) ->
        Logs.info (fun m ->
            m "EVALUATOR : %s : FLOW : CHOICE_START : %s" state.State.request_id (Id.to_string id))
    | Flow.Event.Choice_end (id, ret, state) ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FLOW : CHOICE_END : %s : %s"
              state.State.request_id
              (Id.to_string id)
              (match ret with
              | Ok (choice, _) -> "CHOICE : " ^ Id.to_string choice
              | Error run_err -> "FAILURE : " ^ Flow.show_run_err run_err))
    | Flow.Event.Finally_start (id, state) ->
        Logs.info (fun m ->
            m "EVALUATOR : %s : FLOW : FINALLY_START : %s" state.State.request_id (Id.to_string id))
    | Flow.Event.Finally_resume (id, state) ->
        Logs.info (fun m ->
            m "EVALUATOR : %s : FLOW : FINALLY_RESUME : %s" state.State.request_id (Id.to_string id))
    | Flow.Event.Recover_choice (recover_id, choice_id, state) ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FLOW : RECOVER_CHOICE : %s : %s"
              state.State.request_id
              (Id.to_string recover_id)
              (Id.to_string choice_id))
    | Flow.Event.Recover_start (recover_id, state) ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FLOW : RECOVER_START : %s"
              state.State.request_id
              (Id.to_string recover_id))

  module Access_control = Terrat_access_control.Make (S.Access_control)

  module Access_control_engine = struct
    module Dirspace_map = Terrat_data.Dirspace_map
    module V1 = Terrat_base_repo_config_v1
    module Ac = V1.Access_control
    module P = V1.Access_control.Policy

    type t = {
      config : Terrat_base_repo_config_v1.Access_control.t;
      ctx : S.Access_control.Ctx.t;
      policy_branch : S.Ref.t;
      request_id : string;
      user : string;
    }

    let make ~request_id ~ctx ~repo_config ~user ~policy_branch () =
      let config = V1.access_control repo_config in
      { config; ctx; policy_branch; request_id; user }

    let policy_branch t = S.Ref.to_string t.policy_branch

    let eval_ci_change t diff =
      let ci_config_update = t.config.Ac.ci_config_update in
      if t.config.Ac.enabled then
        Abbs_time_it.run (log_time t.request_id "ACCESS_CONTROL_EVAL_CI_CHANGE") (fun () ->
            let open Abbs_future_combinators.Infix_result_monad in
            Access_control.eval_ci_change t.ctx ci_config_update diff
            >>| function
            | true -> None
            | false -> Some ci_config_update)
      else (
        Logs.info (fun m -> m "EVALUATOR : %s : ACCESS_CONTROL_DISABLED" t.request_id);
        Abb.Future.return (Ok None))

    let eval_files t diff =
      let files_policy = t.config.Ac.files in
      if t.config.Ac.enabled then
        Abbs_time_it.run (log_time t.request_id "ACCESS_CONTROL_FILES") (fun () ->
            let open Abbs_future_combinators.Infix_result_monad in
            Access_control.eval_files t.ctx files_policy diff
            >>| function
            | `Ok -> None
            | `Denied denied -> Some denied)
      else (
        Logs.info (fun m -> m "EVALUATOR : %s : ACCESS_CONTROL_DISABLED" t.request_id);
        Abb.Future.return (Ok None))

    let eval_repo_config t diff =
      let terrateam_config_update = t.config.Ac.terrateam_config_update in
      if t.config.Ac.enabled then
        Abbs_time_it.run (log_time t.request_id "ACCESS_CONTROL_EVAL_REPO_CONFIG") (fun () ->
            let open Abbs_future_combinators.Infix_result_monad in
            Access_control.eval_repo_config t.ctx terrateam_config_update diff
            >>| function
            | true -> None
            | false -> Some terrateam_config_update)
      else (
        Logs.info (fun m -> m "EVALUATOR : %s : ACCESS_CONTROL_DISABLED" t.request_id);
        Abb.Future.return (Ok None))

    let eval' t change_matches selector =
      if t.config.Ac.enabled then
        let policies =
          (* Policies have been specified, but that doesn't mean the specific
             operation that is being executed has a configuration.  So iterate
             through and pluck out the specific configuration and take the
             default if that configuration was not specified. *)
          t.config.Ac.policies
          |> CCList.map (fun ({ P.tag_query; _ } as p) ->
                 Terrat_access_control.Policy.{ tag_query; policy = selector p })
        in
        Abbs_time_it.run (log_time t.request_id "ACCESS_CONTROL_SUPERAPPROVAL_EVAL") (fun () ->
            Access_control.eval t.ctx policies change_matches)
      else (
        Logs.info (fun m -> m "EVALUATOR : %s : ACCESS_CONTROL_DISABLED" t.request_id);
        Abb.Future.return (Ok Terrat_access_control.R.{ pass = change_matches; deny = [] }))

    let eval_superapproved t reviewers change_matches =
      let open Abbs_future_combinators.Infix_result_monad in
      (* First, let's see if this user can even apply any of the denied changes
         if there is a superapproval. If there isn't, we return the original
         response, otherwise we have to see if any of the changes have super
         approvals. *)
      eval' t change_matches (fun { P.apply_with_superapproval; _ } -> apply_with_superapproval)
      >>= function
      | Terrat_access_control.R.{ pass = _ :: _ as pass; deny } ->
          (* Now, of those that passed, let's see if any have been approved by a
             super approver.  To do this we'll iterate over the approvers. *)
          let pass_with_superapproval =
            pass
            |> CCList.map (fun ({ Terrat_change_match3.Dirspace_config.dirspace; _ } as ch) ->
                   (dirspace, ch))
            |> Dirspace_map.of_list
          in
          Abbs_future_combinators.List_result.fold_left
            ~f:(fun acc user ->
              let changes = acc |> Dirspace_map.to_list |> CCList.map snd in
              let ctx = S.Access_control.set_user user t.ctx in
              let t' = { t with ctx } in
              eval' t' changes (fun { P.superapproval; _ } -> superapproval)
              >>= fun Terrat_access_control.R.{ pass; _ } ->
              let acc =
                CCListLabels.fold_left
                  ~f:(fun acc { Terrat_change_match3.Dirspace_config.dirspace; _ } ->
                    Dirspace_map.remove dirspace acc)
                  ~init:acc
                  pass
              in
              Abb.Future.return (Ok acc))
            ~init:pass_with_superapproval
            reviewers
          >>= fun unapproved ->
          Abb.Future.return
            (Ok
               (Dirspace_map.fold
                  (fun k _ acc -> Dirspace_map.remove k acc)
                  unapproved
                  pass_with_superapproval))
      | _ ->
          Logs.debug (fun m ->
              m
                "EVALUATOR : %s : ACCESS_CONTROL : NO_MATCHING_CHANGES_FOR_SUPERAPPROVAL"
                t.request_id);
          Abb.Future.return (Ok Dirspace_map.empty)

    let eval_tf_operation t change_matches = function
      | `Plan -> eval' t change_matches (fun { P.plan; _ } -> plan)
      | `Apply reviewers -> (
          let open Abbs_future_combinators.Infix_result_monad in
          eval' t change_matches (fun { P.apply; _ } -> apply)
          >>= function
          | Terrat_access_control.R.{ pass; deny = _ :: _ as deny } ->
              (* If we have some denies, then let's see if any of them can be
                 applied with because of a super approver.  If not, we'll return
                 the original response. *)
              Logs.debug (fun m ->
                  m "EVALUATOR : %s : ACCESS_CONTROL : EVAL_SUPERAPPROVAL" t.request_id);
              let denied_change_matches =
                CCList.map
                  (fun Terrat_access_control.R.Deny.{ change_match; _ } -> change_match)
                  deny
              in
              eval_superapproved t reviewers denied_change_matches
              >>= fun superapproved ->
              let pass = pass @ (superapproved |> Dirspace_map.to_list |> CCList.map snd) in
              let deny =
                CCList.filter
                  (fun Terrat_access_control.R.Deny.
                         { change_match = { Terrat_change_match3.Dirspace_config.dirspace; _ }; _ } ->
                    not (Dirspace_map.mem dirspace superapproved))
                  deny
              in
              Abb.Future.return (Ok Terrat_access_control.R.{ pass; deny })
          | r -> Abb.Future.return (Ok r))
      | `Apply_force -> eval' t change_matches (fun { P.apply_force; _ } -> apply_force)
      | `Apply_autoapprove ->
          eval' t change_matches (fun { P.apply_autoapprove; _ } -> apply_autoapprove)

    let eval_pr_operation t = function
      | `Unlock ->
          if t.config.Ac.enabled then
            let match_list = t.config.Ac.unlock in
            Abbs_time_it.run (log_time t.request_id "ACCESS_CONTROL_EVAL") (fun () ->
                let open Abbs_future_combinators.Infix_result_monad in
                Access_control.eval_match_list t.ctx match_list
                >>| function
                | true -> None
                | false -> Some match_list)
          else (
            Logs.debug (fun m -> m "EVALUATOR : %s : ACCESS_CONTROL_DISABLED" t.request_id);
            Abb.Future.return (Ok None))

    let plan_require_all_dirspace_access t = t.config.Ac.plan_require_all_dirspace_access
    let apply_require_all_dirspace_access t = t.config.Ac.apply_require_all_dirspace_access
  end

  (* We want to be able to compute some values and have them accessible
     throughout the execution of a flow, like binding a variable but a flow can
     be stopped and started and even started on a different computer, so "later"
     accesses of the value might need to compute it again.  To make more
     seamless, we have derived values, these are a function whose value is
     cached but can be recomputed if lost.  This particular implementation is
     using a process-wide cache, such that if any requests happen to come back
     to the same service, they will not have to recompute their value. *)
  module Dv = struct
    module Matches = struct
      type t = {
        working_set_matches : Terrat_change_match3.Dirspace_config.t list;
        all_matches : Terrat_change_match3.Dirspace_config.t list list;
        all_unapplied_matches : Terrat_change_match3.Dirspace_config.t list list;
      }
      [@@deriving show]
    end

    (* Cache Dv values so there is little to no cost in fetching them
       frequently.  We cache them a unique identifier for the current invocation
       of the flow, that way each flow invocation gets a consistent view of the
       values but as the values change between resumes the values get
       updated. *)
    module Cache = struct
      module Matches = Abb_cache.Lru.Make (struct
        type k = string * S.Account.t * S.Repo.t * S.Ref.t * S.Ref.t * [ `Plan | `Apply ]
        [@@deriving eq]

        type v = Matches.t

        type err =
          [ Repo_config.fetch_err
          | Terrat_change_match3.synthesize_config_err
          ]

        type args = unit -> (v, err) result Abb.Future.t

        let fetch f = f ()
      end)

      module Access_control_eval_tf_op = Abb_cache.Lru.Make (struct
        type k =
          string
          * S.Account.t
          * S.Repo.t
          * int
          * S.Ref.t
          * [ `Plan | `Apply of string list | `Apply_autoapprove | `Apply_force ]
        [@@deriving eq]

        type v = Terrat_access_control.R.t

        type err =
          [ Repo_config.fetch_err
          | Terrat_change_match3.synthesize_config_err
          ]

        type args = unit -> (v, err) result Abb.Future.t

        let fetch f = f ()
      end)

      module Apply_requirements = Abb_cache.Lru.Make (struct
        type k = string [@@deriving eq]
        type v = S.Apply_requirements.t

        type err =
          [ Repo_config.fetch_err
          | Terrat_change_match3.synthesize_config_err
          ]

        type args = unit -> (v, err) result Abb.Future.t

        let fetch f = f ()
      end)

      module Repo_config = Abb_cache.Lru.Make (struct
        type k = string * S.Account.t * S.Repo.t * S.Ref.t [@@deriving eq]
        type v = string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t
        type err = Repo_config.fetch_err
        type args = unit -> (v, err) result Abb.Future.t

        let fetch f = f ()
      end)

      module Pull_request = Abb_cache.Lru.Make (struct
        type k = string * S.Account.t * S.Repo.t * int [@@deriving eq]
        type v = S.Pull_request.fetched S.Pull_request.t
        type err = [ `Error ]
        type args = unit -> (v, err) result Abb.Future.t

        let fetch f = f ()
      end)

      let matches =
        Matches.create
          { Abb_cache.Lru.on_hit = CCFun.const (); on_miss = CCFun.const (); size = 50 }

      let access_control_eval_tf_op =
        Access_control_eval_tf_op.create
          { Abb_cache.Lru.on_hit = CCFun.const (); on_miss = CCFun.const (); size = 50 }

      let apply_requirements =
        Apply_requirements.create
          { Abb_cache.Lru.on_hit = CCFun.const (); on_miss = CCFun.const (); size = 50 }

      let repo_config =
        Repo_config.create
          { Abb_cache.Lru.on_hit = CCFun.const (); on_miss = CCFun.const (); size = 50 }

      let pull_request =
        Pull_request.create
          { Abb_cache.Lru.on_hit = CCFun.const (); on_miss = CCFun.const (); size = 50 }
    end

    let is_interactive ctx state =
      match state.State.event with
      | Event.Pull_request_open _
      | Event.Pull_request_close _
      | Event.Pull_request_sync _
      | Event.Pull_request_ready_for_review _
      | Event.Pull_request_comment _ -> true
      | Event.Push _ | Event.Run_scheduled_drift | Event.Run_drift _ -> false

    let repo_config_system_defaults ctx state =
      let module V1 = Terrat_base_repo_config_v1 in
      match Terrat_config.infracost_pricing_api_endpoint ctx.Ctx.config with
      | Some _ -> Abb.Future.return (Ok V1.default)
      | None ->
          let system_defaults =
            {
              (V1.to_view V1.default) with
              V1.View.cost_estimation = V1.Cost_estimation.make ~enabled:false ();
            }
          in
          Abb.Future.return (Ok (V1.of_view system_defaults))

    let client ctx state =
      create_client state.State.request_id ctx.Ctx.config (Event.account state.State.event)

    let pull_request_safe ctx state =
      match Event.pull_request_id_safe state.State.event with
      | None -> Abb.Future.return (Ok None)
      | Some pull_request_id -> (
          let account = Event.account state.State.event in
          let repo = Event.repo state.State.event in
          let fetch () =
            let open Abbs_future_combinators.Infix_result_monad in
            create_client state.State.request_id ctx.Ctx.config account
            >>= fun client ->
            fetch_pull_request state.State.request_id account client repo pull_request_id
          in
          let open Abb.Future.Infix_monad in
          Abbs_time_it.run
            (fun time ->
              Logs.info (fun m ->
                  m
                    "EVALUATOR : %s : DV : PULL_REQUEST : repo=%s : pull_number=%d : time=%f"
                    state.State.request_id
                    (S.Repo.to_string repo)
                    pull_request_id
                    time))
            (fun () ->
              Cache.Pull_request.fetch
                Cache.pull_request
                (ctx.Ctx.request_id, account, repo, pull_request_id)
                fetch)
          >>= function
          | Ok pull_request -> Abb.Future.return (Ok (Some pull_request))
          | Error `Error -> Abb.Future.return (Error `Error))

    let pull_request ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      pull_request_safe ctx state
      >>= function
      | Some pull_request -> Abb.Future.return (Ok pull_request)
      | None -> assert false

    let target ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      match state.State.event with
      | Event.Pull_request_open _
      | Event.Pull_request_close _
      | Event.Pull_request_sync _
      | Event.Pull_request_ready_for_review _
      | Event.Pull_request_comment _ ->
          pull_request ctx state
          >>= fun pull_request ->
          Abb.Future.return (Ok (Target.Pr (S.Pull_request.stored_of_fetched pull_request)))
      | Event.Run_drift { repo; _ } ->
          client ctx state
          >>= fun client ->
          fetch_remote_repo state.State.request_id client repo
          >>= fun remote_repo ->
          let branch = S.Ref.to_string (S.Remote_repo.default_branch remote_repo) in
          Abb.Future.return (Ok (Target.Drift { repo; branch }))
      | Event.Push _ | Event.Run_scheduled_drift -> assert false

    let branch_ref ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      match Event.pull_request_id_safe state.State.event with
      | Some _ ->
          pull_request ctx state
          >>= fun pull_request -> Abb.Future.return (Ok (S.Pull_request.branch_ref pull_request))
      | None -> (
          client ctx state
          >>= fun client ->
          fetch_remote_repo state.State.request_id client (Event.repo state.State.event)
          >>= fun remote_repo ->
          let default_branch = S.Remote_repo.default_branch remote_repo in
          fetch_branch_sha
            state.State.request_id
            client
            (Event.repo state.State.event)
            default_branch
          >>= function
          | Some branch_sha -> Abb.Future.return (Ok branch_sha)
          | None -> assert false)

    let branch_name ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      match Event.pull_request_id_safe state.State.event with
      | Some _ ->
          pull_request ctx state
          >>= fun pull_request -> Abb.Future.return (Ok (S.Pull_request.branch_name pull_request))
      | None ->
          client ctx state
          >>= fun client ->
          fetch_remote_repo state.State.request_id client (Event.repo state.State.event)
          >>= fun remote_repo -> Abb.Future.return (Ok (S.Remote_repo.default_branch remote_repo))

    let working_branch_ref ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      let default_branch_sha =
        client ctx state
        >>= fun client ->
        fetch_remote_repo state.State.request_id client (Event.repo state.State.event)
        >>= fun remote_repo ->
        let default_branch = S.Remote_repo.default_branch remote_repo in
        fetch_branch_sha state.State.request_id client (Event.repo state.State.event) default_branch
        >>= function
        | Some branch_sha -> Abb.Future.return (Ok branch_sha)
        | None -> assert false
      in
      match Event.pull_request_id_safe state.State.event with
      | Some _ -> (
          pull_request ctx state
          >>= fun pull_request ->
          match S.Pull_request.state pull_request with
          | Terrat_pull_request.State.Open _ | Terrat_pull_request.State.Closed ->
              Abb.Future.return (Ok (S.Pull_request.branch_ref pull_request))
          | Terrat_pull_request.State.Merged _ -> default_branch_sha)
      | None -> default_branch_sha

    let base_ref ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      match Event.pull_request_id_safe state.State.event with
      | Some _ ->
          pull_request ctx state
          >>= fun pull_request -> Abb.Future.return (Ok (S.Pull_request.base_ref pull_request))
      | None -> (
          client ctx state
          >>= fun client ->
          fetch_remote_repo state.State.request_id client (Event.repo state.State.event)
          >>= fun remote_repo ->
          let default_branch = S.Remote_repo.default_branch remote_repo in
          fetch_branch_sha
            state.State.request_id
            client
            (Event.repo state.State.event)
            default_branch
          >>= function
          | Some branch_sha -> Abb.Future.return (Ok branch_sha)
          | None -> assert false)

    let base_branch_name ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      match Event.pull_request_id_safe state.State.event with
      | Some _ ->
          pull_request ctx state
          >>= fun pull_request ->
          Abb.Future.return (Ok (S.Pull_request.base_branch_name pull_request))
      | None ->
          client ctx state
          >>= fun client ->
          fetch_remote_repo state.State.request_id client (Event.repo state.State.event)
          >>= fun remote_repo -> Abb.Future.return (Ok (S.Remote_repo.default_branch remote_repo))

    let query_built_config ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      working_branch_ref ctx state
      >>= fun working_branch_ref' ->
      query_repo_config_json
        state.State.request_id
        ctx.Ctx.storage
        (Event.account state.State.event)
        working_branch_ref'

    let repo_config_with_provenance ctx state =
      let account = Event.account state.State.event in
      let repo = Event.repo state.State.event in
      let fetch () =
        let open Abbs_future_combinators.Infix_result_monad in
        client ctx state
        >>= fun client ->
        branch_ref ctx state
        >>= fun branch_ref' ->
        repo_config_system_defaults ctx state
        >>= fun system_defaults ->
        query_built_config ctx state
        >>= fun built_config ->
        Repo_config.fetch_with_provenance
          ?built_config
          ~system_defaults
          state.State.request_id
          ctx.Ctx.config
          client
          repo
          branch_ref'
      in
      let open Abb.Future.Infix_monad in
      Abbs_time_it.run
        (fun time ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : DV : REPO_CONFIG : account=%s : repo=%s : time=%f"
                state.State.request_id
                (S.Account.to_string account)
                (S.Repo.to_string repo)
                time))
        (fun () ->
          let open Abbs_future_combinators.Infix_result_monad in
          branch_ref ctx state
          >>= fun branch_ref' ->
          Cache.Repo_config.fetch
            Cache.repo_config
            (ctx.Ctx.request_id, account, repo, branch_ref')
            fetch)
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Repo_config.fetch_err as err) -> Abb.Future.return (Error err)

    let repo_config ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      repo_config_with_provenance ctx state
      >>= fun (_, repo_config) -> Abb.Future.return (Ok repo_config)

    let repo_tree_branch ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      let repo = Event.repo state.State.event in
      client ctx state
      >>= fun client ->
      branch_ref ctx state
      >>= fun branch_ref' -> fetch_tree state.State.request_id client repo branch_ref'

    let query_index ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      working_branch_ref ctx state
      >>= fun working_branch_ref' ->
      query_index
        state.State.request_id
        ctx.Ctx.storage
        (Event.account state.State.event)
        working_branch_ref'

    let tag_query ctx state =
      match state.State.event with
      | Event.Pull_request_open _
      | Event.Pull_request_close _
      | Event.Pull_request_sync _
      | Event.Pull_request_ready_for_review _ -> Abb.Future.return (Ok Terrat_tag_query.any)
      | Event.Pull_request_comment
          {
            comment =
              Terrat_comment.(
                ( Plan { tag_query }
                | Apply { tag_query }
                | Apply_autoapprove { tag_query }
                | Apply_force { tag_query } ));
            _;
          } -> Abb.Future.return (Ok tag_query)
      | Event.Run_drift _ ->
          let module V1 = Terrat_base_repo_config_v1 in
          let module D = V1.Drift in
          let open Abbs_future_combinators.Infix_result_monad in
          repo_config ctx state
          >>= fun repo_config ->
          let drift = V1.drift repo_config in
          Abb.Future.return (Ok drift.D.tag_query)
      | Event.Pull_request_comment _ | Event.Push _ | Event.Run_scheduled_drift -> assert false

    let matches ctx state op =
      let compute_matches
          ~ctx
          ~repo_config
          ~tag_query
          ~out_of_change_applies
          ~applied_dirspaces
          ~diff
          ~repo_tree
          ~index
          () =
        let module Dir_set = CCSet.Make (CCString) in
        let open CCResult.Infix in
        Terrat_change_match3.synthesize_config ~index repo_config
        >>= fun config ->
        let out_of_change_dirspace_configs =
          CCList.flat_map
            CCFun.(Terrat_change_match3.of_dirspace config %> CCOption.to_list)
            out_of_change_applies
        in
        let applied_dirspaces = Terrat_data.Dirspace_set.of_list applied_dirspaces in
        let all_matches =
          Terrat_change_match3.match_diff_list
            ~force_matches:out_of_change_dirspace_configs
            config
            diff
        in
        let dirs =
          all_matches
          |> CCList.flatten
          |> CCList.map
               (fun
                 { Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ }; _ }
               -> dir)
          |> Dir_set.of_list
        in
        let existing_dirs =
          Dir_set.filter
            (function
              | "." ->
                  (* The root directory is always there, because...it
                     has to be. *)
                  true
              | d ->
                  let d = d ^ "/" in
                  CCList.exists (CCString.prefix ~pre:d) repo_tree)
            dirs
        in
        (* Filter out any dirspaces that have been applied or refer to a directory
           that no longer exists. This could happen because of
           [out_of_change_applies], these may refer to directories that no longer
           exist, and thus we can't do much about them other than ignore them. *)
        let all_unapplied_matches =
          CCList.filter_map
            (fun layer ->
              let module Dc = Terrat_change_match3.Dirspace_config in
              match
                CCList.filter
                  (fun { Dc.dirspace = { Terrat_dirspace.dir; _ } as dirspace; _ } ->
                    (not (Terrat_data.Dirspace_set.mem dirspace applied_dirspaces))
                    && Dir_set.mem dir existing_dirs)
                  layer
              with
              | [] -> None
              | layer -> Some layer)
            all_matches
        in
        let working_set_matches =
          match all_unapplied_matches with
          | layer :: _ -> CCList.filter (Terrat_change_match3.match_tag_query ~tag_query) layer
          | [] -> []
        in
        Ok (working_set_matches, all_matches, all_unapplied_matches)
      in
      let missing_autoplan_matches db pull_request matches =
        let module Dc = Terrat_change_match3.Dirspace_config in
        let open Abbs_future_combinators.Infix_result_monad in
        query_dirspaces_without_valid_plans
          state.State.request_id
          db
          pull_request
          (CCList.map (fun { Dc.dirspace; _ } -> dirspace) matches)
        >>= fun dirspaces ->
        let dirspaces = Terrat_data.Dirspace_set.of_list dirspaces in
        Abb.Future.return
          (Ok
             (CCList.filter
                (fun { Dc.dirspace; _ } -> Terrat_data.Dirspace_set.mem dirspace dirspaces)
                matches))
      in
      let out_of_change_applies ctx state =
        let open Abbs_future_combinators.Infix_result_monad in
        pull_request_safe ctx state
        >>= function
        | Some pull_request ->
            query_pull_request_out_of_change_applies
              state.State.request_id
              ctx.Ctx.storage
              pull_request
        | None -> Abb.Future.return (Ok [])
      in
      let applied_dirspaces ctx state =
        let open Abbs_future_combinators.Infix_result_monad in
        pull_request_safe ctx state
        >>= function
        | Some pull_request ->
            query_applied_dirspaces state.State.request_id ctx.Ctx.storage pull_request
        | None -> Abb.Future.return (Ok [])
      in
      let diff ctx state =
        let open Abbs_future_combinators.Infix_result_monad in
        pull_request_safe ctx state
        >>= function
        | Some pull_request -> Abb.Future.return (Ok (S.Pull_request.diff pull_request))
        | None ->
            repo_tree_branch ctx state
            >>= fun tree ->
            Abb.Future.return
              (Ok (CCList.map (fun filename -> Terrat_change.Diff.Change { filename }) tree))
      in
      let account = Event.account state.State.event in
      let repo = Event.repo state.State.event in
      let fetch () =
        let open Abbs_future_combinators.Infix_result_monad in
        Abbs_future_combinators.Infix_result_app.(
          (fun repo_config repo_tree -> (repo_config, repo_tree))
          <$> repo_config ctx state
          <*> repo_tree_branch ctx state)
        >>= fun (repo_config, repo_tree) ->
        query_index ctx state
        >>= fun index ->
        out_of_change_applies ctx state
        >>= fun out_of_change_applies ->
        applied_dirspaces ctx state
        >>= fun applied_dirspaces ->
        base_branch_name ctx state
        >>= fun base_branch_name ->
        branch_name ctx state
        >>= fun branch_name ->
        diff ctx state
        >>= fun diff ->
        tag_query ctx state
        >>= fun tag_query ->
        let repo_config =
          Terrat_base_repo_config_v1.derive
            ~ctx:
              (Terrat_base_repo_config_v1.Ctx.make
                 ~dest_branch:(S.Ref.to_string base_branch_name)
                 ~branch:(S.Ref.to_string branch_name)
                 ())
            ~index:
              (CCOption.map_or
                 ~default:Terrat_base_repo_config_v1.Index.empty
                 (fun { Index.index; _ } -> index)
                 index)
            ~file_list:repo_tree
            repo_config
        in
        Abb.Future.return
          (compute_matches
             ~ctx:
               (Terrat_base_repo_config_v1.Ctx.make
                  ~dest_branch:(S.Ref.to_string base_branch_name)
                  ~branch:(S.Ref.to_string branch_name)
                  ())
             ~repo_config
             ~tag_query
             ~out_of_change_applies
             ~applied_dirspaces
             ~diff
             ~repo_tree
             ~index:
               (CCOption.map_or
                  ~default:Terrat_base_repo_config_v1.Index.empty
                  (fun { Index.index; _ } -> index)
                  index)
             ())
        >>= fun (working_set_matches, all_matches, all_unapplied_matches) ->
        pull_request_safe ctx state
        >>= function
        | Some pull_request -> (
            let trigger_type = Event.trigger_type state.State.event in
            match (op, trigger_type) with
            | `Plan, `Auto ->
                let working_set_matches =
                  CCList.filter
                    (fun {
                           Terrat_change_match3.Dirspace_config.when_modified =
                             {
                               Terrat_base_repo_config_v1.When_modified.autoplan;
                               autoplan_draft_pr;
                               _;
                             };
                           _;
                         } ->
                      autoplan
                      && ((not (S.Pull_request.is_draft_pr pull_request)) || autoplan_draft_pr))
                    working_set_matches
                in
                missing_autoplan_matches ctx.Ctx.storage pull_request working_set_matches
                >>= fun working_set_matches ->
                Abb.Future.return
                  (Ok { Matches.working_set_matches; all_matches; all_unapplied_matches })
            | (`Apply | `Apply_autoapprove | `Apply_force), `Auto ->
                let working_set_matches =
                  CCList.filter
                    (fun {
                           Terrat_change_match3.Dirspace_config.when_modified =
                             { Terrat_base_repo_config_v1.When_modified.autoapply; _ };
                           _;
                         } -> autoapply)
                    working_set_matches
                in
                Abb.Future.return
                  (Ok { Matches.working_set_matches; all_matches; all_unapplied_matches })
            | (`Plan | `Apply | `Apply_autoapprove | `Apply_force), `Manual ->
                Abb.Future.return
                  (Ok { Matches.working_set_matches; all_matches; all_unapplied_matches }))
        | None ->
            Abb.Future.return
              (Ok { Matches.working_set_matches; all_matches; all_unapplied_matches })
      in
      let open Abb.Future.Infix_monad in
      Abbs_time_it.run
        (fun time ->
          Logs.info (fun m ->
              m "EVALUATOR : %s : DV : MATCHES : time=%f" state.State.request_id time))
        (fun () ->
          let open Abbs_future_combinators.Infix_result_monad in
          base_ref ctx state
          >>= fun base_ref' ->
          branch_ref ctx state
          >>= fun branch_ref' ->
          let op =
            match op with
            | `Plan -> `Plan
            | `Apply | `Apply_autoapprove | `Apply_force -> `Apply
          in
          Cache.Matches.fetch
            Cache.matches
            (ctx.Ctx.request_id, account, repo, base_ref', branch_ref', op)
            fetch)
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Repo_config.fetch_err as err) -> Abb.Future.return (Error err)
      | Error (#Terrat_change_match3.synthesize_config_err as err) -> Abb.Future.return (Error err)

    let access_control ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun client pull_request repo_config -> (client, pull_request, repo_config))
        <$> client ctx state
        <*> pull_request ctx state
        <*> repo_config ctx state)
      >>= fun (client, pull_request, repo_config) ->
      fetch_remote_repo state.State.request_id client (S.Pull_request.repo pull_request)
      >>= fun remote_repo ->
      Abb.Future.return
        (Ok
           (Access_control_engine.make
              ~request_id:state.State.request_id
              ~ctx:
                (S.create_access_control_ctx
                   ~request_id:state.State.request_id
                   client
                   ctx.Ctx.config
                   (S.Pull_request.repo pull_request)
                   (Event.user state.State.event))
              ~repo_config
              ~user:(S.User.to_string (Event.user state.State.event))
              ~policy_branch:(S.Remote_repo.default_branch remote_repo)
              ()))

    let tf_operation_access_control_evaluation ctx state op =
      let account = Event.account state.State.event in
      let repo = Event.repo state.State.event in
      let pull_request_id = Event.pull_request_id state.State.event in
      let fetch () =
        let open Abbs_future_combinators.Infix_result_monad in
        access_control ctx state
        >>= fun ac ->
        let op' =
          match op with
          | `Apply _ -> `Apply
          | (`Plan | `Apply_autoapprove | `Apply_force) as op -> op
        in
        matches ctx state op'
        >>= fun matches ->
        Access_control_engine.eval_tf_operation ac matches.Matches.working_set_matches op
      in
      let open Abb.Future.Infix_monad in
      Abbs_time_it.run
        (fun time ->
          Logs.info (fun m ->
              m "EVALUATOR : %s : DV : ACCESS_CONTROL_TF_OP : time=%f" state.State.request_id time))
        (fun () ->
          let open Abbs_future_combinators.Infix_result_monad in
          pull_request ctx state
          >>= fun pull_request ->
          Cache.Access_control_eval_tf_op.fetch
            Cache.access_control_eval_tf_op
            ( ctx.Ctx.request_id,
              account,
              repo,
              pull_request_id,
              S.Pull_request.branch_ref pull_request,
              op )
            fetch)
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Repo_config.fetch_err as err) -> Abb.Future.return (Error err)
      | Error (#Terrat_change_match3.synthesize_config_err as err) -> Abb.Future.return (Error err)

    let dirspaces ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      let fetch_dirspace ~system_defaults ?built_config client dest_branch branch repo ref_ =
        Abbs_future_combinators.Infix_result_app.(
          (fun repo_config repo_tree -> (repo_config, repo_tree))
          <$> Repo_config.fetch
                ?built_config
                ~system_defaults
                state.State.request_id
                ctx.Ctx.config
                client
                repo
                ref_
          <*> fetch_tree state.State.request_id client repo ref_)
        >>= fun (repo_config, repo_tree) ->
        let repo_config =
          Terrat_base_repo_config_v1.derive
            ~ctx:(Terrat_base_repo_config_v1.Ctx.make ~dest_branch ~branch ())
            ~index:Terrat_base_repo_config_v1.Index.empty
            ~file_list:repo_tree
            repo_config
        in
        Abb.Future.return
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
        >>= fun config ->
        let matches =
          CCList.flatten
            (Terrat_change_match3.match_diff_list
               config
               (CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) repo_tree))
        in
        let workflows = Terrat_base_repo_config_v1.workflows repo_config in
        let dirspaceflows =
          CCList.map
            (fun ({ Terrat_change_match3.Dirspace_config.dirspace; _ } as change) ->
              Terrat_change.Dirspaceflow.
                {
                  dirspace;
                  workflow =
                    CCOption.map
                      (fun (idx, workflow) -> Workflow.{ idx; workflow })
                      (CCList.find_idx
                         (fun { Terrat_base_repo_config_v1.Workflows.Entry.tag_query; _ } ->
                           Terrat_change_match3.match_tag_query ~tag_query change)
                         workflows);
                })
            matches
        in
        Abb.Future.return
          (Ok
             (CCList.map
                (fun Terrat_change.{ Dirspaceflow.dirspace = Dirspace.{ dir; workspace }; workflow } ->
                  Terrat_api_components.Work_manifest_dir.
                    {
                      path = dir;
                      workspace;
                      workflow =
                        CCOption.map
                          (fun Terrat_change.Dirspaceflow.Workflow.{ idx; _ } -> idx)
                          workflow;
                      rank = 0;
                    })
                dirspaceflows))
      in
      client ctx state
      >>= fun client ->
      base_branch_name ctx state
      >>= fun base_branch_name ->
      branch_name ctx state
      >>= fun branch_name ->
      base_ref ctx state
      >>= fun base_ref ->
      working_branch_ref ctx state
      >>= fun working_branch_ref ->
      let dest_branch_name = S.Ref.to_string base_branch_name in
      let branch_name = S.Ref.to_string branch_name in
      let repo = Event.repo state.State.event in
      repo_config_system_defaults ctx state
      >>= fun system_defaults ->
      query_repo_config_json
        state.State.request_id
        ctx.Ctx.storage
        (Event.account state.State.event)
        base_ref
      >>= fun base_built_config ->
      query_repo_config_json
        state.State.request_id
        ctx.Ctx.storage
        (Event.account state.State.event)
        working_branch_ref
      >>= fun working_branch_built_config ->
      Abbs_future_combinators.Infix_result_app.(
        (fun base_dirspaces dirspaces -> (base_dirspaces, dirspaces))
        <$> fetch_dirspace
              ~system_defaults
              ?built_config:base_built_config
              client
              dest_branch_name
              branch_name
              repo
              base_ref
        <*> fetch_dirspace
              ~system_defaults
              ?built_config:working_branch_built_config
              client
              dest_branch_name
              branch_name
              repo
              working_branch_ref)

    let apply_requirements ctx state =
      let fetch () =
        let open Abbs_future_combinators.Infix_result_monad in
        Abbs_future_combinators.Infix_result_app.(
          (fun client repo_config pull_request matches ->
            (client, repo_config, pull_request, matches))
          <$> client ctx state
          <*> repo_config ctx state
          <*> pull_request ctx state
          <*> matches ctx state `Apply)
        >>= fun (client, repo_config, pull_request, matches) ->
        eval_apply_requirements
          state.State.request_id
          ctx.Ctx.config
          (Event.user state.State.event)
          client
          repo_config
          pull_request
          matches.Matches.working_set_matches
      in
      let open Abb.Future.Infix_monad in
      Abbs_time_it.run
        (fun time ->
          Logs.info (fun m ->
              m "EVALUATOR : %s : DV : APPLY_REQUIREMENTS : time=%f" state.State.request_id time))
        (fun () -> Cache.Apply_requirements.fetch Cache.apply_requirements ctx.Ctx.request_id fetch)
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Repo_config.fetch_err as err) -> Abb.Future.return (Error err)
      | Error (#Terrat_change_match3.synthesize_config_err as err) -> Abb.Future.return (Error err)

    let access_control_results ctx state op =
      let open Abbs_future_combinators.Infix_result_monad in
      match Event.initiator state.State.event with
      | Terrat_work_manifest3.Initiator.User _ -> (
          match op with
          | (`Plan | `Apply_autoapprove | `Apply_force) as op ->
              tf_operation_access_control_evaluation ctx state op
          | `Apply ->
              apply_requirements ctx state
              >>= fun apply_requirements ->
              let access_control_run_type =
                `Apply
                  (CCList.filter_map
                     (fun { Terrat_pull_request_review.user; _ } -> user)
                     (S.Apply_requirements.approved_reviews apply_requirements))
              in
              tf_operation_access_control_evaluation ctx state access_control_run_type)
      | Terrat_work_manifest3.Initiator.System ->
          matches ctx state op
          >>= fun matches ->
          Abb.Future.return
            (Ok { Terrat_access_control.R.pass = matches.Matches.working_set_matches; deny = [] })
  end

  module H = struct
    let log_state_err request_id st input work_manifest_id =
      let string_of_input =
        let open State.Io.I in
        function
        | Work_manifest_initiate _ -> "Work_manifest_initiate"
        | Work_manifest_result _ -> "Work_manifest_result"
        | Work_manifest_run_success -> "Work_manifest_run_success"
        | Work_manifest_run_failure _ -> "Work_manifest_run_failure"
        | Plan_store _ -> "Plan_store"
        | Plan_fetch _ -> "Plan_fetch"
        | Work_manifest_failure _ -> "Work_manifest_failure"
        | Checkpointed -> "Checkpointed"
      in
      Logs.err (fun m ->
          m
            "EVALUATOR %s : STATE_ERROR : st=%a : input=%s : work_manifest_id=%s"
            request_id
            State.St.pp
            st
            (CCOption.map_or ~default:"" string_of_input input)
            (CCOption.map_or ~default:"" Uuidm.to_string work_manifest_id))

    let log_state_err_iter ctx state =
      log_state_err
        state.State.request_id
        state.State.st
        state.State.input
        state.State.work_manifest_id;
      Abb.Future.return (Error `Failure)

    let run_interactive ctx state f =
      if Dv.is_interactive ctx state then f () else Abb.Future.return (Ok ())

    (* Implement a work manifest iteration.  This can create a work manifest if
       one doesn't exist already, update the existing one with new information
       one has already been created, handle run success and failure, and finally
       handle initiate and result.  The only thing this does not handle is
       completing a work manifest, so that iterations can be composed together.
       [fallthrough] is used compose different iter handlers together. *)
    let eval_work_manifest_iter
        ~name
        ~create
        ~update
        ~run_success
        ~run_failure
        ~initiate
        ~result
        ~fallthrough
        ctx
        state =
      let module St = State.St in
      let module I = State.Io.I in
      let module O = State.Io.O in
      let module Wm = Terrat_work_manifest3 in
      let states_of_work_manifests work_manifests =
        CCList.map
          (fun { Wm.id; _ } ->
            { state with State.st = St.Waiting_for_work_manifest_run; work_manifest_id = Some id })
          work_manifests
      in
      let open Abbs_future_combinators.Infix_result_monad in
      match (state.State.st, state.State.input, state.State.work_manifest_id) with
      | St.Initial, None, None -> (
          Logs.info (fun m ->
              m "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : CREATE" state.State.request_id name);
          create ctx state
          >>= function
          | [] -> Abb.Future.return (Error (`Noop state))
          | self :: work_manifests ->
              Abb.Future.return
                (Error
                   (`Clone
                     ( {
                         state with
                         State.st = St.Waiting_for_work_manifest_run;
                         work_manifest_id = Some self.Wm.id;
                       },
                       states_of_work_manifests work_manifests ))))
      | St.Initial, None, Some work_manifest_id -> (
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : UPDATE : id=%a"
                state.State.request_id
                name
                Uuidm.pp
                work_manifest_id);
          query_work_manifest state.State.request_id ctx.Ctx.storage work_manifest_id
          >>= function
          | Some ({ Wm.state = Wm.State.(Queued | Running); _ } as work_manifest) -> (
              update ctx state work_manifest
              >>= function
              | [] -> Abb.Future.return (Ok { state with State.st = St.Initial })
              | work_manifests -> (
                  match
                    CCList.partition
                      (fun { Wm.id; _ } -> Uuidm.equal id work_manifest_id)
                      work_manifests
                  with
                  | [], work_manifests ->
                      let states = states_of_work_manifests work_manifests in
                      Abbs_future_combinators.List_result.iter
                        ~f:(run_success ctx state)
                        work_manifests
                      >>= fun () ->
                      Abb.Future.return
                        (Error
                           (`Clone ({ state with State.st = St.Work_manifest_completed }, states)))
                  | [ self ], work_manifests ->
                      let state = { state with State.work_manifest_id = Some self.Wm.id } in
                      Abbs_future_combinators.List_result.iter
                        ~f:(run_success ctx state)
                        (self :: work_manifests)
                      >>= fun () ->
                      let states = states_of_work_manifests work_manifests in
                      Abb.Future.return
                        (Error
                           (`Clone
                             ( { state with State.st = St.Waiting_for_work_manifest_initiate },
                               states )))
                  | _ :: _, _ -> assert false))
          | Some { Wm.id; state = state'; _ } ->
              Logs.err (fun m ->
                  m
                    "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : UPDATE : INVALID_STATE : id=%a : \
                     state=%s"
                    state.State.request_id
                    name
                    Uuidm.pp
                    id
                    (Wm.State.to_string state'));
              Abb.Future.return (Error `Failure)
          | None ->
              Logs.err (fun m ->
                  m
                    "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : UPDATE : NOT_FOUND : id=%a"
                    state.State.request_id
                    name
                    Uuidm.pp
                    work_manifest_id);
              Abb.Future.return (Error `Failure))
      | St.Waiting_for_work_manifest_run, None, Some _ ->
          (* This should be reached if we cloned some work manifests. *)
          Abb.Future.return (Error (`Yield state))
      | St.Work_manifest_completed, None, Some _ ->
          (* This should be reached if we cloned some work manifests. *)
          Abb.Future.return (Error (`Noop state))
      | St.Waiting_for_work_manifest_run, Some I.Work_manifest_run_success, Some work_manifest_id
        -> (
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : RUN_SUCCESS : id=%a"
                state.State.request_id
                name
                Uuidm.pp
                work_manifest_id);
          query_work_manifest state.State.request_id ctx.Ctx.storage work_manifest_id
          >>= function
          | Some ({ Wm.state = Wm.State.(Queued | Running); _ } as work_manifest) ->
              run_success ctx state work_manifest
              >>= fun () ->
              Abb.Future.return
                (Error
                   (`Yield
                     { state with State.st = St.Waiting_for_work_manifest_initiate; input = None }))
          | Some { Wm.id; state = state'; _ } ->
              Logs.err (fun m ->
                  m
                    "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : RUN_SUCCESS : INVALID_STATE : \
                     id=%a : state=%s"
                    state.State.request_id
                    name
                    Uuidm.pp
                    id
                    (Wm.State.to_string state'));
              Abb.Future.return (Error `Failure)
          | None ->
              Logs.err (fun m ->
                  m
                    "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : RUN_SUCCESS : NOT_FOUND : id=%a"
                    state.State.request_id
                    name
                    Uuidm.pp
                    work_manifest_id);
              Abb.Future.return (Error `Failure))
      | ( St.Waiting_for_work_manifest_run,
          Some (I.Work_manifest_run_failure err),
          Some work_manifest_id ) -> (
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : RUN_FAILURE : id=%a"
                state.State.request_id
                name
                Uuidm.pp
                work_manifest_id);
          query_work_manifest state.State.request_id ctx.Ctx.storage work_manifest_id
          >>= function
          | Some work_manifest ->
              run_failure ctx state err work_manifest
              >>= fun () ->
              Abb.Future.return
                (Error
                   (`Noop { state with State.st = State.St.Work_manifest_completed; input = None }))
          | None ->
              Logs.err (fun m ->
                  m
                    "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : RUN_FAILURE : NOT_FOUND : id=%a"
                    state.State.request_id
                    name
                    Uuidm.pp
                    work_manifest_id);
              Abb.Future.return (Error `Failure))
      | St.Waiting_for_work_manifest_initiate, None, Some _ ->
          Abb.Future.return (Error (`Yield state))
      | ( St.Waiting_for_work_manifest_initiate,
          Some
            (I.Work_manifest_initiate
              {
                encryption_key;
                initiate = { Terrat_api_components.Work_manifest_initiate.run_id; sha };
                p;
              }),
          Some work_manifest_id ) -> (
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : INITIATE : id=%a : run_id=%s : sha=%s"
                state.State.request_id
                name
                Uuidm.pp
                work_manifest_id
                run_id
                sha);
          query_work_manifest state.State.request_id ctx.Ctx.storage work_manifest_id
          >>= function
          | Some ({ Wm.state = Wm.State.(Queued | Running); _ } as work_manifest) -> (
              initiate ctx state encryption_key run_id sha work_manifest
              >>= function
              | Some response ->
                  let open Abb.Future.Infix_monad in
                  Abb.Future.Promise.set p (Ok (Some response))
                  >>= fun () ->
                  Abb.Future.return
                    (Error
                       (`Yield
                         {
                           state with
                           State.st = St.Waiting_for_work_manifest_result;
                           output = None;
                           input = None;
                         }))
              | None -> Abb.Future.return (Error (`Noop state)))
          | Some { Wm.id; state = Wm.State.Aborted; _ } ->
              Logs.info (fun m ->
                  m
                    "EVALUATOR : %s : WORK_MANIFEST_ITER %s : INITIATE : ABORTED : id=%a"
                    state.State.request_id
                    name
                    Uuidm.pp
                    id);
              Abb.Future.return (Error (`Noop state))
          | Some { Wm.id; state = state'; _ } ->
              Logs.err (fun m ->
                  m
                    "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : INITIATE : INVALID_STATE : id=%a : \
                     state=%s"
                    state.State.request_id
                    name
                    Uuidm.pp
                    id
                    (Wm.State.to_string state'));
              Abb.Future.return (Error (`Noop state))
          | None ->
              Logs.err (fun m ->
                  m
                    "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : INITIATE : NOT_FOUND : id=%a"
                    state.State.request_id
                    name
                    Uuidm.pp
                    work_manifest_id);
              Abb.Future.return (Error (`Noop state)))
      | ( St.Waiting_for_work_manifest_result,
          Some (I.Work_manifest_result { result = req; p }),
          Some work_manifest_id ) ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : RESULT : id=%a"
                state.State.request_id
                name
                Uuidm.pp
                work_manifest_id);
          Abbs_future_combinators.with_finally
            (fun () ->
              query_work_manifest state.State.request_id ctx.Ctx.storage work_manifest_id
              >>= function
              | Some ({ Wm.state = Wm.State.(Queued | Running); _ } as work_manifest) -> (
                  let open Abb.Future.Infix_monad in
                  result ctx state req work_manifest
                  >>= function
                  | Ok () ->
                      Abb.Future.return
                        (Ok { state with State.st = St.Initial; input = None; output = None })
                  | Error (`Noop state) ->
                      Abb.Future.return
                        (Error (`Noop { state with State.st = St.Initial; input = None }))
                  | Error err -> Abb.Future.return (Error err))
              | Some { Wm.id; state = state'; _ } ->
                  Logs.err (fun m ->
                      m
                        "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : RESULT : INVALID_STATE : id=%a \
                         : state=%s"
                        state.State.request_id
                        name
                        Uuidm.pp
                        id
                        (Wm.State.to_string state'));
                  Abb.Future.return (Error `Failure)
              | None ->
                  Logs.err (fun m ->
                      m
                        "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : RESULT : NOT_FOUND : id=%a"
                        state.State.request_id
                        name
                        Uuidm.pp
                        work_manifest_id);
                  Abb.Future.return (Error `Failure))
            ~finally:(fun () -> Abb.Future.Promise.set p (Ok ()))
      | _, Some (I.Work_manifest_failure { p }), Some work_manifest_id ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : WORK_MANIFEST_FAILURE : id=%a"
                state.State.request_id
                name
                Uuidm.pp
                work_manifest_id);
          Abbs_future_combinators.with_finally
            (fun () ->
              query_work_manifest state.State.request_id ctx.Ctx.storage work_manifest_id
              >>= function
              | Some ({ Wm.state = Wm.State.(Queued | Running); _ } as work_manifest) ->
                  update_work_manifest_state
                    state.State.request_id
                    ctx.Ctx.storage
                    work_manifest_id
                    Wm.State.Aborted
                  >>= fun () ->
                  run_failure ctx state `Error work_manifest
                  >>= fun () -> Abb.Future.return (Error (`Noop state))
              | Some _ -> Abb.Future.return (Error (`Noop state))
              | None ->
                  Logs.err (fun m ->
                      m
                        "EVALUATOR : %s : WORK_MANIFEST_ITER : %s : WORK_MANIFEST_FAILURE : \
                         NOT_FOUND : id=%a"
                        state.State.request_id
                        name
                        Uuidm.pp
                        work_manifest_id);
                  Abb.Future.return (Error `Failure))
            ~finally:(fun () -> Abb.Future.Promise.set p (Ok ()))
      | _, _, _ -> fallthrough ctx state

    let eval_plan_work_manifest_iter ~store ~fetch ~fallthrough ctx state =
      let module St = State.St in
      let module I = State.Io.I in
      let module O = State.Io.O in
      let open Abbs_future_combinators.Infix_result_monad in
      match (state.State.st, state.State.input, state.State.work_manifest_id) with
      | ( St.Waiting_for_work_manifest_result,
          Some (I.Plan_store { dirspace; data; has_changes; p }),
          Some work_manifest_id ) ->
          store ctx state dirspace data has_changes work_manifest_id
          >>= fun () ->
          let open Abb.Future.Infix_monad in
          Abb.Future.Promise.set p (Ok ())
          >>= fun () -> Abb.Future.return (Error (`Yield { state with State.input = None }))
      | ( St.Waiting_for_work_manifest_result,
          Some (I.Plan_fetch { dirspace; p }),
          Some work_manifest_id ) ->
          fetch ctx state dirspace work_manifest_id
          >>= fun data ->
          let open Abb.Future.Infix_monad in
          Abb.Future.Promise.set p (Ok data)
          >>= fun () ->
          Abb.Future.return (Error (`Yield { state with State.input = None; output = None }))
      | _, _, _ -> fallthrough ctx state

    let initiate_work_manifest state request_id db run_id sha =
      let module Wm = Terrat_work_manifest3 in
      let open Abbs_future_combinators.Infix_result_monad in
      function
      | { Wm.id; branch_ref; state = Wm.State.(Queued | Running); _ }
        when CCString.equal branch_ref sha -> (
          update_work_manifest_run_id request_id db id run_id
          >>= fun () ->
          update_work_manifest_state request_id db id Wm.State.Running
          >>= fun () ->
          query_work_manifest request_id db id
          >>= function
          | Some wm -> Abb.Future.return (Ok (Some wm))
          | None -> assert false)
      | { Wm.id; branch_ref; state = Wm.State.(Queued | Running); _ } ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : MISMATCHED_REFS : id=%a : branch_ref=%s : sha=%s"
                request_id
                Uuidm.pp
                id
                branch_ref
                sha);
          update_work_manifest_run_id request_id db id run_id
          >>= fun () -> Abb.Future.return (Error (`Ref_mismatch_err state))
      | { Wm.id; branch_ref; state = state'; _ } ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : COULD_NOT_INITIATE : id=%a : state=%s : branch_ref=%s : sha=%s"
                request_id
                Uuidm.pp
                id
                (Wm.State.to_string state')
                branch_ref
                sha);
          Abb.Future.return (Ok None)

    let match_tag_queries ~accessor ~changes queries =
      CCList.map
        (fun change ->
          ( change,
            CCList.find_idx
              (fun q -> Terrat_change_match3.match_tag_query ~tag_query:(accessor q) change)
              queries ))
        changes

    let publish_run_failure request_id client user pull_request = function
      | `Error -> publish_msg request_id client user pull_request Msg.Unexpected_temporary_err
      | (`Missing_workflow | `Failed_to_start) as err ->
          publish_msg request_id client user pull_request (Msg.Run_work_manifest_err err)

    let dirspaceflows_of_changes repo_config changes =
      let module R = Terrat_base_repo_config_v1 in
      let workflows = R.workflows repo_config in
      Ok
        (CCList.map
           (fun ({ Terrat_change_match3.Dirspace_config.dirspace; _ }, workflow) ->
             Terrat_change.Dirspaceflow.
               {
                 dirspace;
                 workflow =
                   CCOption.map (fun (idx, workflow) -> Workflow.{ idx; workflow }) workflow;
               })
           (match_tag_queries
              ~accessor:(fun { R.Workflows.Entry.tag_query; _ } -> tag_query)
              ~changes
              workflows))

    let generate_index_run_dirs ctx state wm =
      let module Wm = Terrat_work_manifest3 in
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun client repo_config repo_tree base_branch_name branch_name ->
          (client, repo_config, repo_tree, base_branch_name, branch_name))
        <$> Dv.client ctx state
        <*> Dv.repo_config ctx state
        <*> Dv.repo_tree_branch ctx state
        <*> Dv.base_branch_name ctx state
        <*> Dv.branch_name ctx state)
      >>= fun (client, repo_config, repo_tree, base_branch_name', branch_name') ->
      let dest_branch = S.Ref.to_string base_branch_name' in
      let branch = S.Ref.to_string branch_name' in
      let repo_config =
        Terrat_base_repo_config_v1.derive
          ~ctx:(Terrat_base_repo_config_v1.Ctx.make ~dest_branch ~branch ())
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:repo_tree
          repo_config
      in
      Abb.Future.return
        (Terrat_change_match3.synthesize_config
           ~index:Terrat_base_repo_config_v1.Index.empty
           repo_config)
      >>= fun config ->
      let tag_query = wm.Wm.tag_query in
      let matches =
        CCList.filter
          (Terrat_change_match3.match_tag_query ~tag_query)
          (CCList.flatten
             (Terrat_change_match3.match_diff_list
                config
                (CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) repo_tree)))
      in
      Abb.Future.return (dirspaceflows_of_changes repo_config matches)
      >>= fun dirspaceflows ->
      let module Dsf = Terrat_change.Dirspaceflow in
      let changes =
        CCList.map
          (fun ({ Dsf.workflow; _ } as dsf) ->
            { dsf with Dsf.workflow = CCOption.map (fun Dsf.Workflow.{ idx; _ } -> idx) workflow })
          dirspaceflows
      in
      Abb.Future.return (Ok { wm with Wm.changes })

    let token encryption_key id =
      Base64.encode_exn
        (Cstruct.to_string
           (Mirage_crypto.Hash.SHA256.hmac
              ~key:encryption_key
              (Cstruct.of_string (Uuidm.to_string id))))

    let generate_index_work_manifest_initiate ctx state encryption_key run_id sha work_manifest =
      let module Wm = Terrat_work_manifest3 in
      let open Abbs_future_combinators.Infix_result_monad in
      initiate_work_manifest state state.State.request_id ctx.Ctx.storage run_id sha work_manifest
      >>= function
      | Some ({ Wm.id; branch_ref; base_ref; state = Wm.State.(Queued | Running); _ } as wm) ->
          generate_index_run_dirs ctx state wm
          >>= fun wm ->
          Dv.base_ref ctx state
          >>= fun base_ref' ->
          Dv.repo_config ctx state
          >>= fun repo_config ->
          Dv.repo_tree_branch ctx state
          >>= fun repo_tree ->
          Dv.base_branch_name ctx state
          >>= fun base_branch_name ->
          Dv.branch_name ctx state
          >>= fun branch_name ->
          let repo_config =
            Terrat_base_repo_config_v1.derive
              ~ctx:
                (Terrat_base_repo_config_v1.Ctx.make
                   ~dest_branch:(S.Ref.to_string base_branch_name)
                   ~branch:(S.Ref.to_string branch_name)
                   ())
              ~index:Terrat_base_repo_config_v1.Index.empty
              ~file_list:repo_tree
              repo_config
          in
          let module I = Terrat_api_components.Work_manifest_index in
          let dirs =
            wm.Wm.changes
            |> CCList.map Terrat_change.Dirspaceflow.to_dirspace
            |> CCList.map (fun Terrat_change.Dirspace.{ dir; _ } -> dir)
          in
          let config =
            repo_config
            |> Terrat_base_repo_config_v1.to_version_1
            |> Terrat_repo_config.Version_1.to_yojson
          in
          let response =
            Terrat_api_components.Work_manifest.Work_manifest_index
              {
                I.dirs;
                base_ref = S.Ref.to_string base_ref';
                token = token encryption_key id;
                type_ = "index";
                config;
              }
          in
          Abb.Future.return (Ok (Some response))
      | Some _ | None -> Abb.Future.return (Ok None)

    let generate_index_work_manifest_result ctx state result work_manifest =
      let module Wm = Terrat_work_manifest3 in
      let open Abbs_future_combinators.Infix_result_monad in
      match result with
      | Terrat_api_components.Work_manifest_result.Work_manifest_index_result index ->
          store_index_result state.State.request_id ctx.Ctx.storage work_manifest.Wm.id index
          >>= fun () ->
          store_index state.State.request_id ctx.Ctx.storage work_manifest.Wm.id index
          >>= fun _ ->
          run_interactive ctx state (fun () ->
              let account = Event.account state.State.event in
              let repo = Event.repo state.State.event in
              Dv.client ctx state
              >>= fun client ->
              Dv.pull_request ctx state
              >>= fun pull_request ->
              let module Status = Terrat_commit_check.Status in
              let check =
                S.make_commit_check
                  ~config:ctx.Ctx.config
                  ~description:"Completed"
                  ~title:"terrateam index"
                  ~status:Status.Completed
                  ~work_manifest
                  ~repo
                  account
              in
              create_commit_checks
                state.State.request_id
                client
                repo
                (S.Pull_request.branch_ref pull_request)
                [ check ])
          >>= fun () -> Abb.Future.return (Ok ())
      | Terrat_api_components_work_manifest_result.Work_manifest_tf_operation_result _ ->
          assert false
      | Terrat_api_components_work_manifest_result.Work_manifest_tf_operation_result2 _ ->
          assert false
      | Terrat_api_components_work_manifest_result.Work_manifest_build_config_result _ ->
          assert false

    let maybe_create_completed_apply_check
        request_id
        config
        client
        account
        repo_config
        repo
        pull_request =
      let module R = Terrat_base_repo_config_v1 in
      let apply_requirements = R.apply_requirements repo_config in
      if apply_requirements.R.Apply_requirements.create_completed_apply_check_on_noop then
        let checks =
          [
            S.make_commit_check
              ~config
              ~description:"Completed"
              ~title:"terrateam apply"
              ~status:Terrat_commit_check.Status.Completed
              ~repo
              account;
          ]
        in
        create_commit_checks
          request_id
          client
          (S.Pull_request.repo pull_request)
          (S.Pull_request.branch_ref pull_request)
          checks
      else Abb.Future.return (Ok ())

    let partition_by_environment dirspaceflows =
      let module Dsf = Terrat_change.Dirspaceflow in
      let module We = Terrat_base_repo_config_v1.Workflows.Entry in
      CCListLabels.fold_left
        ~f:(fun acc dsf ->
          match dsf with
          | { Dsf.workflow = Some { Dsf.Workflow.workflow = { We.environment; _ }; _ }; _ } ->
              Terrat_data.String_map.add_to_list (CCOption.get_or ~default:"" environment) dsf acc
          | _ -> Terrat_data.String_map.add_to_list "" dsf acc)
        ~init:Terrat_data.String_map.empty
        dirspaceflows

    let create_op_commit_checks
        request_id
        config
        client
        account
        repo
        ref_
        work_manifest
        description
        status =
      let module Wm = Terrat_work_manifest3 in
      let module Status = Terrat_commit_check.Status in
      match work_manifest.Wm.changes with
      | [] -> Abb.Future.return (Ok ())
      | dirspaces ->
          let run_type =
            match CCList.rev work_manifest.Wm.steps with
            | [] -> assert false
            | step :: _ -> Wm.Step.to_string step
          in
          let aggregate =
            [
              S.make_commit_check
                ~config
                ~description
                ~title:(Printf.sprintf "terrateam %s pre-hooks" run_type)
                ~status
                ~work_manifest
                ~repo
                account;
              S.make_commit_check
                ~config
                ~description
                ~title:(Printf.sprintf "terrateam %s post-hooks" run_type)
                ~status
                ~work_manifest
                ~repo
                account;
            ]
          in
          let dirspace_checks =
            let module Ds = Terrat_change.Dirspace in
            let module Dsf = Terrat_change.Dirspaceflow in
            CCList.map
              (fun { Dsf.dirspace = { Ds.dir; workspace; _ }; _ } ->
                S.make_commit_check
                  ~config
                  ~description
                  ~title:(Printf.sprintf "terrateam %s: %s %s" run_type dir workspace)
                  ~status
                  ~work_manifest
                  ~repo
                  account)
              dirspaces
          in
          let checks = aggregate @ dirspace_checks in
          create_commit_checks request_id client repo ref_ checks

    let create_op_commit_checks_of_result
        request_id
        config
        client
        account
        repo
        ref_
        work_manifest
        result =
      let module Wm = Terrat_work_manifest3 in
      let module Wmr = Work_manifest_result in
      let module Status = Terrat_commit_check.Status in
      let status = function
        | true -> Terrat_commit_check.Status.Completed
        | false -> Terrat_commit_check.Status.Failed
      in
      let description = function
        | true -> "Completed"
        | false -> "Failed"
      in
      let run_type =
        match CCList.rev work_manifest.Wm.steps with
        | [] -> assert false
        | step :: _ -> Wm.Step.to_string step
      in
      let aggregate =
        [
          S.make_commit_check
            ~config
            ~description:(description result.Wmr.pre_hooks_success)
            ~title:(Printf.sprintf "terrateam %s pre-hooks" run_type)
            ~status:(status result.Wmr.pre_hooks_success)
            ~work_manifest
            ~repo
            account;
          S.make_commit_check
            ~config
            ~description:(description result.Wmr.post_hooks_success)
            ~title:(Printf.sprintf "terrateam %s post-hooks" run_type)
            ~status:(status result.Wmr.post_hooks_success)
            ~work_manifest
            ~repo
            account;
        ]
      in
      let dirspace_checks =
        let module Ds = Terrat_change.Dirspace in
        let module Dsf = Terrat_change.Dirspaceflow in
        CCList.map
          (fun ({ Terrat_dirspace.dir; workspace }, success) ->
            S.make_commit_check
              ~config
              ~description:(description success)
              ~title:(Printf.sprintf "terrateam %s: %s %s" run_type dir workspace)
              ~status:(status success)
              ~work_manifest
              ~repo
              account)
          result.Wmr.dirspaces_success
      in
      let checks = aggregate @ dirspace_checks in
      create_commit_checks request_id client repo ref_ checks

    let make_work_manifest
        state
        base_ref
        branch_ref
        changes
        denied_dirspaces
        environment
        tag_query
        target
        op =
      let module Wm = Terrat_work_manifest3 in
      {
        Wm.account = Event.account state.State.event;
        base_ref = S.Ref.to_string base_ref;
        branch_ref = S.Ref.to_string branch_ref;
        changes;
        completed_at = None;
        created_at = ();
        denied_dirspaces;
        environment;
        id = ();
        initiator = Event.initiator state.State.event;
        run_id = ();
        state = ();
        steps =
          [
            (match op with
            | `Plan -> Wm.Step.Plan
            | `Apply | `Apply_force -> Wm.Step.Apply
            | `Apply_autoapprove -> Wm.Step.Unsafe_apply);
          ];
        tag_query;
        target;
      }

    let maybe_create_pending_apply_commit_checks
        request_id
        config
        client
        account
        repo
        ref_
        all_matches
        apply_requirements =
      let module Ar = Terrat_base_repo_config_v1.Apply_requirements in
      let module String_set = CCSet.Make (CCString) in
      if apply_requirements.Ar.create_pending_apply_check then
        let open Abbs_future_combinators.Infix_result_monad in
        fetch_commit_checks request_id client repo ref_
        >>= fun commit_checks ->
        let commit_check_titles =
          commit_checks
          |> CCList.map (fun Terrat_commit_check.{ title; _ } -> title)
          |> String_set.of_list
        in
        let missing_commit_checks =
          all_matches
          |> CCList.filter_map
               (fun
                 {
                   Terrat_change_match3.Dirspace_config.dirspace =
                     { Terrat_dirspace.dir; workspace };
                   when_modified = { Terrat_base_repo_config_v1.When_modified.autoapply; _ };
                   _;
                 }
               ->
                 let name = Printf.sprintf "terrateam apply: %s %s" dir workspace in
                 if (not autoapply) && not (String_set.mem name commit_check_titles) then
                   Some
                     (S.make_commit_check
                        ~config
                        ~description:"Waiting"
                        ~title:(Printf.sprintf "terrateam apply: %s %s" dir workspace)
                        ~status:Terrat_commit_check.Status.Queued
                        ~repo
                        account)
                 else None)
        in
        let missing_apply_check =
          if not (String_set.mem "terrateam apply" commit_check_titles) then
            [
              S.make_commit_check
                ~config
                ~description:"Waiting"
                ~title:"terrateam apply"
                ~status:Terrat_commit_check.Status.Queued
                ~repo
                account;
            ]
          else []
        in
        create_commit_checks
          request_id
          client
          repo
          ref_
          (missing_apply_check @ missing_commit_checks)
      else Abb.Future.return (Ok ())

    let run_op_work_manifest_iter_create op ctx state =
      let module Wm = Terrat_work_manifest3 in
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun repo_config base_ref branch_ref working_branch_ref matches access_control_results ->
          (repo_config, base_ref, branch_ref, working_branch_ref, matches, access_control_results))
        <$> Dv.repo_config ctx state
        <*> Dv.base_ref ctx state
        <*> Dv.branch_ref ctx state
        <*> Dv.working_branch_ref ctx state
        <*> Dv.matches ctx state op
        <*> Dv.access_control_results ctx state op)
      >>= fun ( repo_config,
                base_ref,
                branch_ref,
                working_branch_ref,
                matches,
                access_control_results ) ->
      let { Terrat_access_control.R.pass = passed_dirspaces; deny = denied_dirspaces } =
        access_control_results
      in
      Abb.Future.return
        (dirspaceflows_of_changes repo_config (CCList.flatten matches.Dv.Matches.all_matches))
      >>= fun all_dirspaceflows ->
      store_dirspaceflows
        ~base_ref
        ~branch_ref
        state.State.request_id
        ctx.Ctx.storage
        (Event.repo state.State.event)
        all_dirspaceflows
      >>= fun () ->
      Abb.Future.return (dirspaceflows_of_changes repo_config passed_dirspaces)
      >>= fun dirspaceflows ->
      let denied_dirspaces =
        let module Ac = Terrat_access_control in
        let module Dc = Terrat_change_match3.Dirspace_config in
        CCList.map
          (fun { Ac.R.Deny.change_match = { Dc.dirspace; _ }; policy } ->
            { Wm.Deny.dirspace; policy })
          denied_dirspaces
      in
      let dirspaceflows_by_environment = partition_by_environment dirspaceflows in
      Abbs_future_combinators.List_result.map
        ~f:(fun (environment, dirspaceflows) ->
          let changes =
            let module Dsf = Terrat_change.Dirspaceflow in
            CCList.map
              (fun ({ Dsf.workflow; _ } as dsf) ->
                {
                  dsf with
                  Dsf.workflow = CCOption.map (fun Dsf.Workflow.{ idx; _ } -> idx) workflow;
                })
              dirspaceflows
          in
          let environment =
            match environment with
            | "" -> None
            | env -> Some env
          in
          Dv.target ctx state
          >>= fun target ->
          Dv.tag_query ctx state
          >>= fun tag_query ->
          let work_manifest =
            make_work_manifest
              state
              base_ref
              working_branch_ref
              changes
              denied_dirspaces
              environment
              tag_query
              target
              op
          in
          create_work_manifest state.State.request_id ctx.Ctx.storage work_manifest
          >>= fun work_manifest ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : CREATED_WORK_MANIFEST : id=%a : base_ref=%s : branch_ref=%s : \
                 env=%s"
                state.State.request_id
                Uuidm.pp
                work_manifest.Wm.id
                (S.Ref.to_string base_ref)
                (S.Ref.to_string branch_ref)
                (CCOption.get_or ~default:"" work_manifest.Wm.environment));
          run_interactive ctx state (fun () ->
              Dv.client ctx state
              >>= fun client ->
              create_op_commit_checks
                state.State.request_id
                ctx.Ctx.config
                client
                (Event.account state.State.event)
                (Event.repo state.State.event)
                branch_ref
                work_manifest
                "Queued"
                Terrat_commit_check.Status.Queued
              >>= fun () ->
              maybe_create_pending_apply_commit_checks
                state.State.request_id
                ctx.Ctx.config
                client
                (Event.account state.State.event)
                (Event.repo state.State.event)
                branch_ref
                (CCList.flatten matches.Dv.Matches.all_matches)
                (Terrat_base_repo_config_v1.apply_requirements repo_config))
          >>= fun () -> Abb.Future.return (Ok work_manifest))
        (Terrat_data.String_map.to_list dirspaceflows_by_environment)

    let run_op_work_manifest_iter_update op ctx state work_manifest =
      let module Wm = Terrat_work_manifest3 in
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun repo_config base_ref branch_ref working_branch_ref matches access_control_results ->
          (repo_config, base_ref, branch_ref, working_branch_ref, matches, access_control_results))
        <$> Dv.repo_config ctx state
        <*> Dv.base_ref ctx state
        <*> Dv.branch_ref ctx state
        <*> Dv.working_branch_ref ctx state
        <*> Dv.matches ctx state op
        <*> Dv.access_control_results ctx state op)
      >>= fun ( repo_config,
                base_ref,
                branch_ref,
                working_branch_ref,
                matches,
                access_control_results ) ->
      let { Terrat_access_control.R.pass = passed_dirspaces; deny = denied_dirspaces } =
        access_control_results
      in
      Abb.Future.return
        (dirspaceflows_of_changes repo_config (CCList.flatten matches.Dv.Matches.all_matches))
      >>= fun all_dirspaceflows ->
      store_dirspaceflows
        ~base_ref
        ~branch_ref
        state.State.request_id
        ctx.Ctx.storage
        (Event.repo state.State.event)
        all_dirspaceflows
      >>= fun () ->
      Abb.Future.return (dirspaceflows_of_changes repo_config passed_dirspaces)
      >>= fun dirspaceflows ->
      let denied_dirspaces =
        let module Ac = Terrat_access_control in
        let module Dc = Terrat_change_match3.Dirspace_config in
        CCList.map
          (fun { Ac.R.Deny.change_match = { Dc.dirspace; _ }; policy } ->
            { Wm.Deny.dirspace; policy })
          denied_dirspaces
      in
      let dirspaceflows_by_environment = partition_by_environment dirspaceflows in
      Abbs_future_combinators.List_result.map
        ~f:(fun (environment, dirspaceflows) ->
          let changes =
            let module Dsf = Terrat_change.Dirspaceflow in
            CCList.map
              (fun ({ Dsf.workflow; _ } as dsf) ->
                {
                  dsf with
                  Dsf.workflow = CCOption.map (fun Dsf.Workflow.{ idx; _ } -> idx) workflow;
                })
              dirspaceflows
          in
          let environment =
            match environment with
            | "" -> None
            | env -> Some env
          in
          if CCOption.equal CCString.equal work_manifest.Wm.environment environment then
            let work_manifest =
              {
                work_manifest with
                Wm.changes;
                denied_dirspaces;
                steps =
                  work_manifest.Wm.steps
                  @ [
                      (match op with
                      | `Plan -> Wm.Step.Plan
                      | `Apply | `Apply_force -> Wm.Step.Apply
                      | `Apply_autoapprove -> Wm.Step.Unsafe_apply);
                    ];
              }
            in
            update_work_manifest_changes
              state.State.request_id
              ctx.Ctx.storage
              work_manifest.Wm.id
              changes
            >>= fun () ->
            update_work_manifest_denied_dirspaces
              state.State.request_id
              ctx.Ctx.storage
              work_manifest.Wm.id
              denied_dirspaces
            >>= fun () ->
            update_work_manifest_steps
              state.State.request_id
              ctx.Ctx.storage
              work_manifest.Wm.id
              work_manifest.Wm.steps
            >>= fun () ->
            run_interactive ctx state (fun () ->
                Dv.client ctx state
                >>= fun client ->
                create_op_commit_checks
                  state.State.request_id
                  ctx.Ctx.config
                  client
                  (Event.account state.State.event)
                  (Event.repo state.State.event)
                  branch_ref
                  work_manifest
                  "Queued"
                  Terrat_commit_check.Status.Queued
                >>= fun () ->
                maybe_create_pending_apply_commit_checks
                  state.State.request_id
                  ctx.Ctx.config
                  client
                  (Event.account state.State.event)
                  (Event.repo state.State.event)
                  branch_ref
                  (CCList.flatten matches.Dv.Matches.all_matches)
                  (Terrat_base_repo_config_v1.apply_requirements repo_config))
            >>= fun () -> Abb.Future.return (Ok work_manifest)
          else
            Dv.target ctx state
            >>= fun target ->
            Dv.tag_query ctx state
            >>= fun tag_query ->
            let work_manifest =
              make_work_manifest
                state
                base_ref
                working_branch_ref
                changes
                denied_dirspaces
                environment
                tag_query
                target
                op
            in
            create_work_manifest state.State.request_id ctx.Ctx.storage work_manifest
            >>= fun work_manifest ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : CREATED_WORK_MANIFEST : id=%a : base_ref=%s : branch_ref=%s : \
                   env=%s"
                  state.State.request_id
                  Uuidm.pp
                  work_manifest.Wm.id
                  (S.Ref.to_string base_ref)
                  (S.Ref.to_string branch_ref)
                  (CCOption.get_or ~default:"" work_manifest.Wm.environment));
            run_interactive ctx state (fun () ->
                Dv.client ctx state
                >>= fun client ->
                create_op_commit_checks
                  state.State.request_id
                  ctx.Ctx.config
                  client
                  (Event.account state.State.event)
                  (Event.repo state.State.event)
                  branch_ref
                  work_manifest
                  "Queued"
                  Terrat_commit_check.Status.Queued
                >>= fun () ->
                maybe_create_pending_apply_commit_checks
                  state.State.request_id
                  ctx.Ctx.config
                  client
                  (Event.account state.State.event)
                  (Event.repo state.State.event)
                  branch_ref
                  (CCList.flatten matches.Dv.Matches.all_matches)
                  (Terrat_base_repo_config_v1.apply_requirements repo_config))
            >>= fun () -> Abb.Future.return (Ok work_manifest))
        (Terrat_data.String_map.to_list dirspaceflows_by_environment)

    let run_op_work_manifest_iter_run_success op ctx state work_manifest =
      let maybe_publish_autoapply_running request_id client user pull_request = function
        | `Apply | `Apply_autoapprove | `Apply_force ->
            if Event.trigger_type state.State.event = `Auto then
              publish_msg request_id client user pull_request Msg.Autoapply_running
            else Abb.Future.return (Ok ())
        | `Plan -> Abb.Future.return (Ok ())
      in
      run_interactive ctx state (fun () ->
          let open Abbs_future_combinators.Infix_result_monad in
          Dv.client ctx state
          >>= fun client ->
          Dv.pull_request ctx state
          >>= fun pull_request ->
          let module Status = Terrat_commit_check.Status in
          create_op_commit_checks
            state.State.request_id
            ctx.Ctx.config
            client
            (Event.account state.State.event)
            (S.Pull_request.repo pull_request)
            (S.Pull_request.branch_ref pull_request)
            work_manifest
            "Running"
            Status.Running
          >>= fun () ->
          maybe_publish_autoapply_running
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            op
          >>= fun () -> Abb.Future.return (Ok ()))

    let run_op_work_manifest_iter_run_failure ctx state err work_manifest =
      let open Abbs_future_combinators.Infix_result_monad in
      run_interactive ctx state (fun () ->
          Dv.client ctx state
          >>= fun client ->
          Dv.pull_request ctx state
          >>= fun pull_request ->
          let module Status = Terrat_commit_check.Status in
          create_op_commit_checks
            state.State.request_id
            ctx.Ctx.config
            client
            (Event.account state.State.event)
            (S.Pull_request.repo pull_request)
            (S.Pull_request.branch_ref pull_request)
            work_manifest
            "Failed"
            Status.Failed
          >>= fun () ->
          publish_run_failure
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            err
          >>= fun () -> Abb.Future.return (Error `Failure))
      >>= fun () -> Abb.Future.return (Error `Failure)

    let token encryption_key id =
      Base64.encode_exn
        (Cstruct.to_string
           (Mirage_crypto.Hash.SHA256.hmac
              ~key:encryption_key
              (Cstruct.of_string (Uuidm.to_string id))))

    let changed_dirspaces changes =
      let module Tc = Terrat_change in
      let module Dsf = Tc.Dirspaceflow in
      CCList.map
        (fun Tc.{ Dsf.dirspace = { Dirspace.dir; workspace }; workflow } ->
          (* TODO: Provide correct rank *)
          Terrat_api_components.Work_manifest_dir.{ path = dir; workspace; workflow; rank = 0 })
        changes

    let run_op_work_manifest_iter_initiate ctx state encryption_key run_id sha work_manifest =
      let module Wm = Terrat_work_manifest3 in
      let open Abbs_future_combinators.Infix_result_monad in
      initiate_work_manifest state state.State.request_id ctx.Ctx.storage run_id sha work_manifest
      >>= function
      | Some { Wm.steps; base_ref; branch_ref; changes; target; _ } -> (
          Dv.base_branch_name ctx state
          >>= fun base_branch_name ->
          let step =
            match CCList.rev steps with
            | [] -> assert false
            | step :: _ -> step
          in
          let run_kind =
            match (target, step) with
            | Target.Pr pr, (Wm.Step.Apply | Wm.Step.Plan | Wm.Step.Unsafe_apply) ->
                `Pull_request pr
            | Target.Pr _, Wm.Step.Index -> `Index
            | Target.Pr _, Wm.Step.Build_config -> `Build_config
            | Target.Drift _, _ -> `Drift
          in
          let run_kind_str =
            match run_kind with
            | `Pull_request _ -> "pr"
            | `Index -> "index"
            | `Drift -> "drift"
            | `Build_config -> "build-config"
          in
          let run_kind_data =
            let module Rkd = Terrat_api_components.Work_manifest_plan.Run_kind_data in
            let module Rkdpr = Terrat_api_components.Run_kind_data_pull_request in
            match run_kind with
            | `Pull_request pr ->
                Some
                  (Rkd.Run_kind_data_pull_request
                     { Rkdpr.id = CCInt.to_string (S.Pull_request.id pr) })
            | `Index | `Drift | `Build_config -> None
          in
          match step with
          | Wm.Step.Plan ->
              Dv.repo_config ctx state
              >>= fun repo_config ->
              Dv.repo_tree_branch ctx state
              >>= fun repo_tree ->
              Dv.base_branch_name ctx state
              >>= fun base_branch_name ->
              Dv.branch_name ctx state
              >>= fun branch_name ->
              Dv.query_index ctx state
              >>= fun index ->
              let repo_config =
                Terrat_base_repo_config_v1.derive
                  ~ctx:
                    (Terrat_base_repo_config_v1.Ctx.make
                       ~dest_branch:(S.Ref.to_string base_branch_name)
                       ~branch:(S.Ref.to_string branch_name)
                       ())
                  ~index:
                    (CCOption.map_or
                       ~default:Terrat_base_repo_config_v1.Index.empty
                       (fun { Index.index; _ } -> index)
                       index)
                  ~file_list:repo_tree
                  repo_config
              in
              Dv.dirspaces ctx state
              >>= fun (base_dirspaces, dirspaces) ->
              Abb.Future.return
                (Ok
                   (Some
                      Terrat_api_components.(
                        Work_manifest.Work_manifest_plan
                          {
                            Work_manifest_plan.token = token encryption_key work_manifest.Wm.id;
                            base_dirspaces;
                            base_ref = S.Ref.to_string base_branch_name;
                            changed_dirspaces = changed_dirspaces changes;
                            dirspaces;
                            run_kind = run_kind_str;
                            run_kind_data;
                            type_ = "plan";
                            result_version;
                            config =
                              repo_config
                              |> Terrat_base_repo_config_v1.to_version_1
                              |> Terrat_repo_config.Version_1.to_yojson;
                          })))
          | Wm.Step.(Apply | Unsafe_apply) ->
              Dv.repo_config ctx state
              >>= fun repo_config ->
              Dv.repo_tree_branch ctx state
              >>= fun repo_tree ->
              Dv.base_branch_name ctx state
              >>= fun base_branch_name ->
              Dv.branch_name ctx state
              >>= fun branch_name ->
              Dv.query_index ctx state
              >>= fun index ->
              let repo_config =
                Terrat_base_repo_config_v1.derive
                  ~ctx:
                    (Terrat_base_repo_config_v1.Ctx.make
                       ~dest_branch:(S.Ref.to_string base_branch_name)
                       ~branch:(S.Ref.to_string branch_name)
                       ())
                  ~index:
                    (CCOption.map_or
                       ~default:Terrat_base_repo_config_v1.Index.empty
                       (fun { Index.index; _ } -> index)
                       index)
                  ~file_list:repo_tree
                  repo_config
              in
              Abb.Future.return
                (Ok
                   (Some
                      Terrat_api_components.(
                        Work_manifest.Work_manifest_apply
                          {
                            Work_manifest_apply.token = token encryption_key work_manifest.Wm.id;
                            base_ref = S.Ref.to_string base_branch_name;
                            changed_dirspaces = changed_dirspaces changes;
                            run_kind = run_kind_str;
                            type_ = "apply";
                            result_version;
                            config =
                              repo_config
                              |> Terrat_base_repo_config_v1.to_version_1
                              |> Terrat_repo_config.Version_1.to_yojson;
                          })))
          | Wm.Step.Index -> assert false
          | Wm.Step.Build_config -> assert false)
      | None -> Abb.Future.return (Ok None)

    let run_op_work_manifest_iter_result op ctx state result work_manifest =
      let module Wm = Terrat_work_manifest3 in
      let open Abbs_future_combinators.Infix_result_monad in
      match result with
      | Terrat_api_components_work_manifest_result.Work_manifest_index_result _ -> assert false
      | Terrat_api_components_work_manifest_result.Work_manifest_build_config_result _ ->
          assert false
      | Terrat_api_components_work_manifest_result.Work_manifest_tf_operation_result2 result ->
          Dv.client ctx state
          >>= fun client ->
          Dv.matches ctx state op
          >>= fun matches ->
          let work_manifest_result = S.work_manifest_result2 result in
          store_tf_operation_result2
            state.State.request_id
            ctx.Ctx.storage
            work_manifest.Wm.id
            result
          >>= fun () ->
          run_interactive ctx state (fun () ->
              Dv.pull_request ctx state
              >>= fun pull_request ->
              create_op_commit_checks_of_result
                state.State.request_id
                ctx.Ctx.config
                client
                work_manifest.Wm.account
                (S.Pull_request.repo pull_request)
                (S.Pull_request.branch_ref pull_request)
                work_manifest
                work_manifest_result
              >>= fun () ->
              publish_msg
                state.State.request_id
                client
                (Event.user state.State.event)
                pull_request
                (Msg.Tf_op_result2
                   {
                     config = ctx.Ctx.config;
                     is_layered_run = CCList.length matches.Dv.Matches.all_matches > 1;
                     remaining_layers = matches.Dv.Matches.all_unapplied_matches;
                     result;
                     work_manifest;
                   }))
          >>= fun () ->
          if not work_manifest_result.Work_manifest_result.overall_success then
            (* If the run failed, then we're done. *)
            Abb.Future.return (Error (`Noop state))
          else Abb.Future.return (Ok ())
      | Terrat_api_components_work_manifest_result.Work_manifest_tf_operation_result result ->
          Dv.client ctx state
          >>= fun client ->
          Dv.matches ctx state op
          >>= fun matches ->
          let work_manifest_result = S.work_manifest_result result in
          store_tf_operation_result
            state.State.request_id
            ctx.Ctx.storage
            work_manifest.Wm.id
            result
          >>= fun () ->
          run_interactive ctx state (fun () ->
              Dv.pull_request ctx state
              >>= fun pull_request ->
              create_op_commit_checks_of_result
                state.State.request_id
                ctx.Ctx.config
                client
                work_manifest.Wm.account
                (S.Pull_request.repo pull_request)
                (S.Pull_request.branch_ref pull_request)
                work_manifest
                work_manifest_result
              >>= fun () ->
              publish_msg
                state.State.request_id
                client
                (Event.user state.State.event)
                pull_request
                (Msg.Tf_op_result
                   {
                     is_layered_run = CCList.length matches.Dv.Matches.all_matches > 1;
                     remaining_layers = matches.Dv.Matches.all_unapplied_matches;
                     result;
                     work_manifest;
                   }))
          >>= fun () ->
          if not work_manifest_result.Work_manifest_result.overall_success then
            (* If the run failed, then we're done. *)
            Abb.Future.return (Error (`Noop state))
          else Abb.Future.return (Ok ())

    let run_op_work_manifest_plan_iter_store ctx state dirspace data has_changes work_manifest_id =
      store_plan
        state.State.request_id
        ctx.Ctx.storage
        work_manifest_id
        dirspace
        (Base64.decode_exn data)
        has_changes

    let run_op_work_manifest_plan_iter_fetch ctx state dirspace work_manifest_id =
      let open Abbs_future_combinators.Infix_result_monad in
      fetch_plan state.State.request_id ctx.Ctx.storage work_manifest_id dirspace
      >>= fun data -> Abb.Future.return (Ok (CCOption.map Base64.encode_exn data))
  end

  module F = struct
    let store_account_repository ctx state =
      match state.State.event with
      | Event.Pull_request_open { account; repo; _ }
      | Event.Pull_request_close { account; repo; _ }
      | Event.Pull_request_sync { account; repo; _ }
      | Event.Pull_request_ready_for_review { account; repo; _ }
      | Event.Pull_request_comment { account; repo; _ }
      | Event.Push { account; repo; _ }
      | Event.Run_drift { account; repo; _ } ->
          let open Abbs_future_combinators.Infix_result_monad in
          store_account_repository state.State.request_id ctx.Ctx.storage account repo
          >>= fun () ->
          (* Checkpoint here so that we do not hold up any other runs for this
             repository with a db lock *)
          Abb.Future.return (Error (`Checkpoint state))
      | Event.Run_scheduled_drift -> Abb.Future.return (Ok state)

    let test_account_status ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      query_account_status state.State.request_id ctx.Ctx.storage (Event.account state.State.event)
      >>= function
      | `Active -> Abb.Future.return (Ok (Id.Account_enabled, state))
      | `Expired -> Abb.Future.return (Ok (Id.Account_expired, state))
      | `Disabled -> Abb.Future.return (Ok (Id.Account_disabled, state))

    let account_disabled _ state =
      Prmths.Counter.inc_one Metrics.op_on_account_disabled_total;
      Logs.info (fun m -> m "EVALUATOR : %s : ACCOUNT_DISABLED" state.State.request_id);
      Abb.Future.return (Error (`Noop state))

    let test_event_kind ctx state =
      match state.State.event with
      | Event.Pull_request_open _
      | Event.Pull_request_close _
      | Event.Pull_request_sync _
      | Event.Pull_request_ready_for_review _
      | Event.Pull_request_comment
          { comment = Terrat_comment.(Plan _ | Apply _ | Apply_autoapprove _ | Apply_force _); _ }
        -> Abb.Future.return (Ok (Id.Event_kind_op, state))
      | Event.Pull_request_comment { comment = Terrat_comment.Help; _ } ->
          Abb.Future.return (Ok (Id.Event_kind_help, state))
      | Event.Pull_request_comment { comment = Terrat_comment.Unlock _; _ } ->
          Abb.Future.return (Ok (Id.Event_kind_unlock, state))
      | Event.Pull_request_comment { comment = Terrat_comment.Repo_config; _ } ->
          Abb.Future.return (Ok (Id.Event_kind_repo_config, state))
      | Event.Pull_request_comment { comment = Terrat_comment.Feedback _; _ } ->
          Abb.Future.return (Ok (Id.Event_kind_feedback, state))
      | Event.Pull_request_comment { comment = Terrat_comment.Index; _ } ->
          Abb.Future.return (Ok (Id.Event_kind_index, state))
      | Event.Push _ -> Abb.Future.return (Ok (Id.Event_kind_push, state))
      | Event.Run_scheduled_drift -> Abb.Future.return (Ok (Id.Event_kind_run_drift, state))
      | Event.Run_drift _ ->
          (* This event type is only created internally *)
          assert false

    let test_index_required ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.repo_config ctx state
      >>= fun repo_config ->
      Dv.query_index ctx state
      >>= fun index ->
      let module R = Terrat_base_repo_config_v1 in
      match (R.indexer repo_config, index) with
      | { R.Indexer.enabled = true; _ }, None -> Abb.Future.return (Ok (Id.Index_required, state))
      | _ -> Abb.Future.return (Ok (Id.Index_not_required, state))

    let run_index_work_manifest_iter =
      H.eval_work_manifest_iter
        ~name:"INDEX"
        ~create:(fun ctx state ->
          let module Wm = Terrat_work_manifest3 in
          let open Abbs_future_combinators.Infix_result_monad in
          let account = Event.account state.State.event in
          let repo = Event.repo state.State.event in
          Dv.client ctx state
          >>= fun client ->
          Dv.base_ref ctx state
          >>= fun base_ref' ->
          Dv.working_branch_ref ctx state
          >>= fun working_branch_ref' ->
          Dv.target ctx state
          >>= fun target ->
          let work_manifest =
            {
              Wm.account;
              base_ref = S.Ref.to_string base_ref';
              branch_ref = S.Ref.to_string working_branch_ref';
              changes = [];
              completed_at = None;
              created_at = ();
              denied_dirspaces = [];
              environment = None;
              id = ();
              initiator = Event.initiator state.State.event;
              run_id = ();
              state = ();
              steps = [ Wm.Step.Index ];
              tag_query = Terrat_tag_query.any;
              target;
            }
          in
          create_work_manifest state.State.request_id ctx.Ctx.storage work_manifest
          >>= fun work_manifest ->
          H.run_interactive ctx state (fun () ->
              let module Status = Terrat_commit_check.Status in
              Dv.branch_ref ctx state
              >>= fun branch_ref' ->
              let check =
                S.make_commit_check
                  ~config:ctx.Ctx.config
                  ~description:"Queued"
                  ~title:"terrateam index"
                  ~status:Status.Queued
                  ~work_manifest
                  ~repo
                  account
              in
              create_commit_checks state.State.request_id client repo branch_ref' [ check ])
          >>= fun () ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : CREATED_WORK_MANIFEST : id=%a : base_ref=%s : branch_ref=%s"
                state.State.request_id
                Uuidm.pp
                work_manifest.Wm.id
                (S.Ref.to_string base_ref')
                (S.Ref.to_string working_branch_ref'));
          Abb.Future.return (Ok [ work_manifest ]))
        ~update:(fun ctx state work_manifest ->
          let module Wm = Terrat_work_manifest3 in
          let open Abbs_future_combinators.Infix_result_monad in
          let work_manifest =
            { work_manifest with Wm.steps = work_manifest.Wm.steps @ [ Wm.Step.Index ] }
          in
          update_work_manifest_steps
            state.State.request_id
            ctx.Ctx.storage
            work_manifest.Wm.id
            work_manifest.Wm.steps
          >>= fun () ->
          H.run_interactive ctx state (fun () ->
              let module Status = Terrat_commit_check.Status in
              let account = Event.account state.State.event in
              let repo = Event.repo state.State.event in
              Dv.client ctx state
              >>= fun client ->
              Dv.branch_ref ctx state
              >>= fun branch_ref' ->
              let check =
                S.make_commit_check
                  ~config:ctx.Ctx.config
                  ~description:"Queued"
                  ~title:"terrateam index"
                  ~status:Status.Queued
                  ~work_manifest
                  ~repo
                  account
              in
              create_commit_checks state.State.request_id client repo branch_ref' [ check ])
          >>= fun () -> Abb.Future.return (Ok [ work_manifest ]))
        ~run_success:(fun ctx state work_manifest ->
          H.run_interactive ctx state (fun () ->
              let open Abbs_future_combinators.Infix_result_monad in
              let account = Event.account state.State.event in
              let repo = Event.repo state.State.event in
              Dv.client ctx state
              >>= fun client ->
              Dv.pull_request ctx state
              >>= fun pull_request ->
              let module Status = Terrat_commit_check.Status in
              let check =
                S.make_commit_check
                  ~config:ctx.Ctx.config
                  ~description:"Running"
                  ~title:"terrateam index"
                  ~status:Status.Running
                  ~work_manifest
                  ~repo
                  account
              in
              create_commit_checks
                state.State.request_id
                client
                repo
                (S.Pull_request.branch_ref pull_request)
                [ check ]
              >>= fun () -> Abb.Future.return (Ok ())))
        ~run_failure:(fun ctx state err work_manifest ->
          let open Abbs_future_combinators.Infix_result_monad in
          H.run_interactive ctx state (fun () ->
              let account = Event.account state.State.event in
              let repo = Event.repo state.State.event in
              Dv.client ctx state
              >>= fun client ->
              Dv.pull_request ctx state
              >>= fun pull_request ->
              let module Status = Terrat_commit_check.Status in
              let check =
                S.make_commit_check
                  ~config:ctx.Ctx.config
                  ~description:"Failed"
                  ~title:"terrateam index"
                  ~status:Status.Failed
                  ~work_manifest
                  ~repo
                  account
              in
              create_commit_checks
                state.State.request_id
                client
                repo
                (S.Pull_request.branch_ref pull_request)
                [ check ]
              >>= fun () ->
              H.publish_run_failure
                state.State.request_id
                client
                (Event.user state.State.event)
                pull_request
                err
              >>= fun () -> Abb.Future.return (Error `Failure))
          >>= fun () -> Abb.Future.return (Error `Failure))
        ~initiate:H.generate_index_work_manifest_initiate
        ~result:H.generate_index_work_manifest_result
        ~fallthrough:H.log_state_err_iter

    let publish_repo_config ctx state =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Abbs_future_combinators.Infix_result_app.(
          (fun client pull_request repo_config repo_tree ->
            (client, pull_request, repo_config, repo_tree))
          <$> Dv.client ctx state
          <*> Dv.pull_request ctx state
          <*> Dv.repo_config_with_provenance ctx state
          <*> Dv.repo_tree_branch ctx state)
        >>= fun (client, pull_request, (provenance, repo_config), repo_tree) ->
        Dv.query_index ctx state
        >>= fun index ->
        let index =
          let module R = Terrat_base_repo_config_v1 in
          match R.indexer repo_config with
          | { R.Indexer.enabled = true; _ } ->
              CCOption.map_or
                ~default:Terrat_base_repo_config_v1.Index.empty
                (fun { Index.index; _ } -> index)
                index
          | _ -> Terrat_base_repo_config_v1.Index.empty
        in
        let repo_config =
          Terrat_base_repo_config_v1.derive
            ~ctx:
              (Terrat_base_repo_config_v1.Ctx.make
                 ~dest_branch:(S.Ref.to_string (S.Pull_request.base_branch_name pull_request))
                 ~branch:(S.Ref.to_string (S.Pull_request.branch_name pull_request))
                 ())
            ~index
            ~file_list:repo_tree
            repo_config
        in
        match Terrat_change_match3.synthesize_config ~index repo_config with
        | Ok config ->
            publish_msg
              state.State.request_id
              client
              (Event.user state.State.event)
              pull_request
              (Msg.Repo_config (provenance, repo_config))
            >>= fun () -> Abb.Future.return (Ok state)
        | Error (`Bad_glob_err s) ->
            let open Abb.Future.Infix_monad in
            Logs.err (fun m -> m "EVALUATOR : %s : BAD_GLOB : %s" state.State.request_id s);
            Abbs_future_combinators.ignore
              (publish_msg
                 state.State.request_id
                 client
                 (Event.user state.State.event)
                 pull_request
                 (Msg.Bad_glob s))
            >>= fun () -> Abb.Future.return (Error `Error)
        | Error (`Depends_on_cycle_err cycle) ->
            let open Abb.Future.Infix_monad in
            Logs.err (fun m ->
                m
                  "EVALUATOR : %s : DEPENDS_ON_CYCLE : %s"
                  state.State.request_id
                  (CCString.concat
                     " -> "
                     (CCList.map
                        (fun { Terrat_dirspace.dir; workspace } ->
                          "(" ^ dir ^ ", " ^ workspace ^ ")")
                        cycle)));
            Abbs_future_combinators.ignore
              (publish_msg
                 state.State.request_id
                 client
                 (Event.user state.State.event)
                 pull_request
                 (Msg.Depends_on_cycle cycle))
            >>= fun () -> Abb.Future.return (Error `Error)
      in
      let open Abb.Future.Infix_monad in
      run >>= fun _ -> Abb.Future.return (Ok state)

    let publish_help ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.client ctx state
      >>= fun client ->
      Dv.pull_request ctx state
      >>= fun pull_request ->
      publish_msg state.State.request_id client (Event.user state.State.event) pull_request Msg.Help
      >>= fun () -> Abb.Future.return (Ok state)

    let publish_index ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.client ctx state
      >>= fun client ->
      Dv.pull_request ctx state
      >>= fun pull_request ->
      Dv.query_index ctx state
      >>= function
      | Some index ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Index_complete
               ( index.Index.success,
                 CCList.map
                   (fun { Index.Failure.file; line_num; error } -> (file, line_num, error))
                   index.Index.failures ))
          >>= fun () -> Abb.Future.return (Ok state)
      | None -> assert false

    let check_enabled_in_repo_config ctx state =
      let module V1 = Terrat_base_repo_config_v1 in
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.repo_config ctx state
      >>= fun repo_config ->
      if V1.enabled repo_config then Abb.Future.return (Ok state)
      else Abb.Future.return (Error (`Noop state))

    let react_to_comment ctx state =
      match state.State.event with
      | Event.Pull_request_comment { account; repo; comment_id; _ } ->
          let open Abbs_future_combinators.Infix_result_monad in
          Dv.client ctx state
          >>= fun client ->
          react_to_comment state.State.request_id client repo comment_id
          >>= fun () -> Abb.Future.return (Ok state)
      | Event.Pull_request_open _
      | Event.Pull_request_close _
      | Event.Pull_request_sync _
      | Event.Pull_request_ready_for_review _
      | Event.Push _
      | Event.Run_scheduled_drift
      | Event.Run_drift _ -> Abb.Future.return (Ok state)

    let store_pull_request ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.client ctx state
      >>= fun client ->
      Dv.pull_request ctx state
      >>= fun pull_request ->
      store_pull_request state.State.request_id ctx.Ctx.storage pull_request
      >>= fun () -> Abb.Future.return (Ok state)

    let record_feedback ctx state =
      match state.State.event with
      | Event.Pull_request_comment
          { account; repo; user; comment = Terrat_comment.Feedback feedback; pull_request_id; _ } ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : FEEDBACK : account=%s : repo=%s : pull_number=%d : user=%s : %s"
                state.State.request_id
                (S.Account.to_string account)
                (S.Repo.to_string repo)
                pull_request_id
                (S.User.to_string user)
                feedback);
          Abb.Future.return (Ok state)
      | Event.Pull_request_comment _
      | Event.Pull_request_open _
      | Event.Pull_request_close _
      | Event.Pull_request_sync _
      | Event.Pull_request_ready_for_review _
      | Event.Push _
      | Event.Run_scheduled_drift
      | Event.Run_drift _ ->
          Logs.err (fun m -> m "EVALUATOR : %s : NOT_FEEDBACK_COMMENT" state.State.request_id);
          Abb.Future.return (Ok state)

    let complete_work_manifest ctx state =
      let maybe_complete_work_manifest work_manifest_id =
        let module Wm = Terrat_work_manifest3 in
        let open Abbs_future_combinators.Infix_result_monad in
        query_work_manifest state.State.request_id ctx.Ctx.storage work_manifest_id
        >>= function
        | Some { Wm.state = Wm.State.(Queued | Running); _ } ->
            update_work_manifest_state
              state.State.request_id
              ctx.Ctx.storage
              work_manifest_id
              Wm.State.Completed
        | Some _ | None -> Abb.Future.return (Ok ())
      in
      match (state.State.st, state.State.input, state.State.work_manifest_id) with
      | (State.St.Initial | State.St.Work_manifest_completed), _, Some work_manifest_id ->
          let open Abbs_future_combinators.Infix_result_monad in
          update_work_manifest_state
            state.State.request_id
            ctx.Ctx.storage
            work_manifest_id
            Terrat_work_manifest3.State.Completed
          >>= fun () ->
          Abb.Future.return
            (Error (`Yield { state with State.st = State.St.Waiting_for_work_manifest_initiate }))
      | ( State.St.Waiting_for_work_manifest_initiate,
          Some (State.Io.I.Work_manifest_initiate { p; _ }),
          Some work_manifest_id ) ->
          let module D = Terrat_api_components.Work_manifest_done in
          let response =
            Terrat_api_components.Work_manifest.Work_manifest_done { D.type_ = "done" }
          in
          let open Abb.Future.Infix_monad in
          Abb.Future.Promise.set p (Ok (Some response))
          >>= fun () ->
          let open Abbs_future_combinators.Infix_result_monad in
          maybe_complete_work_manifest work_manifest_id
          >>= fun () ->
          Abb.Future.return
            (Ok { state with State.st = State.St.Initial; input = None; output = None })
      | _, _, None ->
          (* No work manifest was run so ignore *)
          Abb.Future.return (Ok state)
      | _, _, _ ->
          H.log_state_err
            state.State.request_id
            state.State.st
            state.State.input
            state.State.work_manifest_id;
          assert false

    let unlock ctx state =
      let repo = Event.repo state.State.event in
      let parse_unlock_ids pull_request_id = function
        | [] -> Ok [ Unlock_id.Pull_request pull_request_id ]
        | unlock_ids ->
            CCResult.map_l
              (function
                | "drift" -> Ok Unlock_id.Drift
                | s -> (
                    match CCInt.of_string s with
                    | Some n -> Ok (Unlock_id.Pull_request n)
                    | None -> Error (`Invalid_unlock_id s)))
              unlock_ids
      in
      let run state client pull_request unlock_ids =
        let open Abbs_future_combinators.Infix_result_monad in
        Dv.repo_config ctx state
        >>= fun repo_config ->
        fetch_remote_repo state.State.request_id client repo
        >>= fun remote_repo ->
        Dv.access_control ctx state
        >>= fun access_control ->
        let open Abb.Future.Infix_monad in
        Access_control_engine.eval_pr_operation access_control `Unlock
        >>= function
        | Ok None ->
            Prmths.Counter.inc_one (Metrics.access_control_total ~t:"unlock" ~r:"allowed");
            let open Abbs_future_combinators.Infix_result_monad in
            Abbs_future_combinators.List_result.iter
              ~f:(unlock state.State.request_id ctx.Ctx.storage repo)
              unlock_ids
            >>= fun () ->
            publish_msg
              state.State.request_id
              client
              (Event.user state.State.event)
              pull_request
              Msg.Unlock_success
            >>= fun () -> Abb.Future.return (Ok state)
        | Ok (Some match_list) ->
            let open Abbs_future_combinators.Infix_result_monad in
            Prmths.Counter.inc_one (Metrics.access_control_total ~t:"unlock" ~r:"denied");
            publish_msg
              state.State.request_id
              client
              (Event.user state.State.event)
              pull_request
              (Msg.Access_control_denied
                 (Access_control_engine.policy_branch access_control, `Unlock match_list))
            >>= fun () -> Abb.Future.return (Ok state)
        | Error `Error ->
            let open Abbs_future_combinators.Infix_result_monad in
            Prmths.Counter.inc_one (Metrics.access_control_total ~t:"unlock" ~r:"denied");
            publish_msg
              state.State.request_id
              client
              (Event.user state.State.event)
              pull_request
              (Msg.Access_control_denied
                 (Access_control_engine.policy_branch access_control, `Lookup_err))
            >>= fun () -> Abb.Future.return (Error `Error)
      in
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.client ctx state
      >>= fun client ->
      Dv.pull_request ctx state
      >>= fun pull_request ->
      let open Abb.Future.Infix_monad in
      Abb.Future.return
        (parse_unlock_ids (S.Pull_request.id pull_request) (Event.unlock_ids state.State.event))
      >>= function
      | Ok unlock_ids -> (
          run state client pull_request unlock_ids
          >>= function
          | Ok _ as r -> Abb.Future.return r
          | Error (#Repo_config.fetch_err as err) -> Abb.Future.return (Error err))
      | Error (`Invalid_unlock_id s) ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Invalid_unlock_id s)
          >>= fun _ -> Abb.Future.return (Error `Error)

    let test_op_kind ctx state =
      match state.State.event with
      | Event.Pull_request_open _
      | Event.Pull_request_sync _
      | Event.Pull_request_ready_for_review _
      | Event.Pull_request_comment { comment = Terrat_comment.Plan _; _ } ->
          Abb.Future.return (Ok (Id.Op_kind_plan, state))
      | Event.Pull_request_comment { comment = Terrat_comment.Apply _; _ } ->
          Abb.Future.return (Ok (Id.Op_kind_apply, state))
      | Event.Pull_request_comment { comment = Terrat_comment.Apply_autoapprove _; _ } ->
          Abb.Future.return (Ok (Id.Op_kind_apply_autoapprove, state))
      | Event.Pull_request_comment { comment = Terrat_comment.Apply_force _; _ } ->
          Abb.Future.return (Ok (Id.Op_kind_apply_force, state))
      | Event.Pull_request_close _ -> Abb.Future.return (Ok (Id.Op_kind_apply, state))
      | Event.Run_scheduled_drift -> Abb.Future.return (Ok (Id.Event_kind_run_drift, state))
      | Event.Pull_request_comment
          { comment = Terrat_comment.(Feedback _ | Help | Repo_config | Unlock _ | Index); _ } ->
          assert false
      | Event.Push _ | Event.Run_drift _ -> assert false

    let check_pull_request_state ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.pull_request ctx state
      >>= fun pull_request ->
      match S.Pull_request.state pull_request with
      | Terrat_pull_request.State.Closed ->
          Logs.info (fun m -> m "EVALUATOR : %s : NOOP : PR_CLOSED" state.State.request_id);
          Abb.Future.return (Error (`Noop state))
      | Terrat_pull_request.State.(Open _ | Merged _) -> Abb.Future.return (Ok state)

    let check_non_empty_matches ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.access_control_results ctx state `Plan
      >>= fun { Terrat_access_control.R.pass = working_set_matches; _ } ->
      let trigger_type = Event.trigger_type state.State.event in
      match (working_set_matches, trigger_type) with
      | [], `Auto ->
          Logs.info (fun m ->
              m "EVALUATOR : %s : NOOP : AUTOPLAN_NO_MATCHES" state.State.request_id);
          Abbs_future_combinators.Infix_result_app.(
            (fun pull_request repo_config -> (pull_request, repo_config))
            <$> Dv.pull_request ctx state
            <*> Dv.repo_config ctx state)
          >>= fun (pull_request, repo_config) ->
          Dv.client ctx state
          >>= fun client ->
          H.maybe_create_completed_apply_check
            state.State.request_id
            ctx.Ctx.config
            client
            (Event.account state.State.event)
            repo_config
            (Event.repo state.State.event)
            pull_request
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | [], `Manual ->
          Logs.info (fun m ->
              m "EVALUATOR : %s : PLAN_NO_MATCHING_DIRSPACES" state.State.request_id);
          Dv.pull_request ctx state
          >>= fun pull_request ->
          Dv.client ctx state
          >>= fun client ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            Msg.Plan_no_matching_dirspaces
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | _ :: _, _ -> Abb.Future.return (Ok state)

    let check_account_status_expired ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      query_account_status state.State.request_id ctx.Ctx.storage (Event.account state.State.event)
      >>= function
      | `Active -> Abb.Future.return (Ok state)
      | `Expired | `Disabled ->
          Logs.info (fun m -> m "EVALUATOR : %s : ACCOUNT_EXPIRED" state.State.request_id);
          Dv.client ctx state
          >>= fun client ->
          Dv.pull_request ctx state
          >>= fun pull_request ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            Msg.Account_expired
          >>= fun () -> Abb.Future.return (Error (`Noop state))

    let check_access_control_ci_change ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun access_control pull_request -> (access_control, pull_request))
        <$> Dv.access_control ctx state
        <*> Dv.pull_request ctx state)
      >>= fun (access_control, pull_request) ->
      let open Abb.Future.Infix_monad in
      Access_control_engine.eval_ci_change access_control (S.Pull_request.diff pull_request)
      >>= function
      | Ok None -> Abb.Future.return (Ok state)
      | Ok (Some match_list) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Dv.client ctx state
          >>= fun client ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Access_control_denied
               (Access_control_engine.policy_branch access_control, `Ci_config_update match_list))
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | Error `Error ->
          let open Abbs_future_combinators.Infix_result_monad in
          Abbs_future_combinators.Infix_result_app.(
            (fun client pull_request -> (client, pull_request))
            <$> Dv.client ctx state
            <*> Dv.pull_request ctx state)
          >>= fun (client, pull_request) ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Access_control_denied
               (Access_control_engine.policy_branch access_control, `Lookup_err))
          >>= fun () -> Abb.Future.return (Error (`Noop state))

    let check_access_control_files ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun access_control pull_request -> (access_control, pull_request))
        <$> Dv.access_control ctx state
        <*> Dv.pull_request ctx state)
      >>= fun (access_control, pull_request) ->
      let open Abb.Future.Infix_monad in
      Access_control_engine.eval_files access_control (S.Pull_request.diff pull_request)
      >>= function
      | Ok None -> Abb.Future.return (Ok state)
      | Ok (Some (fname, match_list)) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Dv.client ctx state
          >>= fun client ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Access_control_denied
               (Access_control_engine.policy_branch access_control, `Files (fname, match_list)))
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | Error `Error ->
          let open Abbs_future_combinators.Infix_result_monad in
          Abbs_future_combinators.Infix_result_app.(
            (fun client pull_request -> (client, pull_request))
            <$> Dv.client ctx state
            <*> Dv.pull_request ctx state)
          >>= fun (client, pull_request) ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Access_control_denied
               (Access_control_engine.policy_branch access_control, `Lookup_err))
          >>= fun () -> Abb.Future.return (Error (`Noop state))

    let check_access_control_repo_config ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun access_control pull_request -> (access_control, pull_request))
        <$> Dv.access_control ctx state
        <*> Dv.pull_request ctx state)
      >>= fun (access_control, pull_request) ->
      let open Abb.Future.Infix_monad in
      Access_control_engine.eval_repo_config access_control (S.Pull_request.diff pull_request)
      >>= function
      | Ok None -> Abb.Future.return (Ok state)
      | Ok (Some match_list) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Dv.client ctx state
          >>= fun client ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Access_control_denied
               ( Access_control_engine.policy_branch access_control,
                 `Terrateam_config_update match_list ))
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | Error `Error ->
          let open Abbs_future_combinators.Infix_result_monad in
          Abbs_future_combinators.Infix_result_app.(
            (fun client pull_request -> (client, pull_request))
            <$> Dv.client ctx state
            <*> Dv.pull_request ctx state)
          >>= fun (client, pull_request) ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Access_control_denied
               (Access_control_engine.policy_branch access_control, `Lookup_err))
          >>= fun () -> Abb.Future.return (Error (`Noop state))

    let check_valid_destination_branch ctx state =
      (* Turn a glob into lua pattern for checking.  We escape all lua pattern
         special characters "().%+-?[^$", turn * into ".*", and wrap the whole thing
         in ^ and $ to make it a complete string match. *)
      let pattern_of_glob s =
        let len = CCString.length s in
        let b = Buffer.create len in
        Buffer.add_char b '^';
        for i = 0 to len - 1 do
          match CCString.get s i with
          | '*' -> Buffer.add_string b ".*"
          | ('(' | ')' | '.' | '%' | '+' | '-' | '?' | '[' | '^' | '$') as c ->
              Buffer.add_char b '%';
              Buffer.add_char b c
          | c -> Buffer.add_char b c
        done;
        Buffer.add_char b '$';
        let pattern = Buffer.contents b in
        CCOption.get_exn_or ("pattern_glob " ^ s ^ " " ^ pattern) (Lua_pattern.of_string pattern)
      in
      let rec eval_destination_branch_match dest_branch source_branch =
        let module Ds = Terrat_base_repo_config_v1.Destination_branches.Destination_branch in
        function
        | [] -> Error `No_matching_dest_branch
        | { Ds.branch; source_branches } :: valid_branches -> (
            let branch_glob = pattern_of_glob (CCString.lowercase_ascii branch) in
            match Lua_pattern.find dest_branch branch_glob with
            | Some _ ->
                (* Partition the source branches into the not patterns and the
                   positive patterns. *)
                let not_branches, branches =
                  CCList.partition (CCString.prefix ~pre:"!") source_branches
                in
                (* Remove the exclamation point from the beginning as it's not
                   actually part of the pattern. *)
                let not_branch_globs =
                  CCList.map
                    CCFun.(CCString.drop 1 %> CCString.lowercase_ascii %> pattern_of_glob)
                    not_branches
                in
                let branch_globs =
                  let branches =
                    (* If there are not-branch globs, but branch globs is empty,
                       that implicitly means match anything on the positive branch.
                       If not-branches are empty then take what is in branches,
                       which could be nothing. *)
                    match (not_branch_globs, branches) with
                    | _ :: _, [] -> [ "*" ]
                    | _, branches -> branches
                  in
                  CCList.map CCFun.(CCString.lowercase_ascii %> pattern_of_glob) branches
                in
                (* The not patterns are an "and", as in success for the not patterns
                   is that all of them do not match.

                   The positive matches, however, are if any of them match. *)
                if
                  CCList.for_all
                    CCFun.(Lua_pattern.find source_branch %> CCOption.is_none)
                    not_branch_globs
                  && CCList.exists
                       CCFun.(Lua_pattern.find source_branch %> CCOption.is_some)
                       branch_globs
                then Ok ()
                else Error `No_matching_source_branch
            | None ->
                (* If the dest branch doesn't match this branch, then try the next *)
                eval_destination_branch_match dest_branch source_branch valid_branches)
      in
      let module Rc = Terrat_base_repo_config_v1 in
      let module Ds = Rc.Destination_branches.Destination_branch in
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun client pull_request repo_config -> (client, pull_request, repo_config))
        <$> Dv.client ctx state
        <*> Dv.pull_request ctx state
        <*> Dv.repo_config ctx state)
      >>= fun (client, pull_request, repo_config) ->
      fetch_remote_repo state.State.request_id client (S.Pull_request.repo pull_request)
      >>= fun remote_repo ->
      let default_branch = S.Remote_repo.default_branch remote_repo in
      let base_branch_name = S.Pull_request.base_branch_name pull_request in
      let branch_name = S.Pull_request.branch_name pull_request in
      let valid_branches =
        match Rc.destination_branches repo_config with
        | [] -> [ Ds.make ~branch:(S.Ref.to_string default_branch) () ]
        | ds -> ds
      in
      let dest_branch = CCString.lowercase_ascii (S.Ref.to_string base_branch_name) in
      let source_branch = CCString.lowercase_ascii (S.Ref.to_string branch_name) in
      match eval_destination_branch_match dest_branch source_branch valid_branches with
      | Ok () -> Abb.Future.return (Ok state)
      | Error `No_matching_dest_branch -> (
          match Event.trigger_type state.State.event with
          | `Auto ->
              Logs.info (fun m ->
                  m
                    "EVALUATOR : %s : DEST_BRANCH_NOT_VALID : branch=%s"
                    state.State.request_id
                    (S.Ref.to_string base_branch_name));
              Abb.Future.return (Error (`Noop state))
          | `Manual ->
              let open Abbs_future_combinators.Infix_result_monad in
              Logs.info (fun m ->
                  m
                    "EVALUATOR : %s : DEST_BRANCH_NOT_VALID_BRANCH_EXPLICIT : branch=%s"
                    state.State.request_id
                    (S.Ref.to_string base_branch_name));
              publish_msg
                state.State.request_id
                client
                (Event.user state.State.event)
                pull_request
                (Msg.Dest_branch_no_match pull_request)
              >>= fun () -> Abb.Future.return (Error `Error))
      | Error `No_matching_source_branch -> (
          match Event.trigger_type state.State.event with
          | `Auto ->
              Logs.info (fun m ->
                  m
                    "EVALUATOR : %s : SOURCE_BRANCH_NOT_VALID : branch=%s"
                    state.State.request_id
                    (S.Ref.to_string branch_name));
              Abb.Future.return (Error (`Noop state))
          | `Manual ->
              let open Abbs_future_combinators.Infix_result_monad in
              Logs.info (fun m ->
                  m
                    "EVALUATOR : %s : SOURCE_BRANCH_NOT_VALID_BRANCH_EXPLICIT : branch=%s"
                    state.State.request_id
                    (S.Ref.to_string branch_name));
              publish_msg
                state.State.request_id
                client
                (Event.user state.State.event)
                pull_request
                (Msg.Dest_branch_no_match pull_request)
              >>= fun () -> Abb.Future.return (Error (`Noop state)))

    let check_access_control_plan ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.access_control ctx state
      >>= fun access_control ->
      let open Abb.Future.Infix_monad in
      Dv.tf_operation_access_control_evaluation ctx state `Plan
      >>= function
      | Ok { Terrat_access_control.R.pass = []; deny = _ :: _ as deny }
        when not (Access_control_engine.plan_require_all_dirspace_access access_control) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Abbs_future_combinators.Infix_result_app.(
            (fun client pull_request -> (client, pull_request))
            <$> Dv.client ctx state
            <*> Dv.pull_request ctx state)
          >>= fun (client, pull_request) ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Access_control_denied
               (Access_control_engine.policy_branch access_control, `All_dirspaces deny))
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | Ok { Terrat_access_control.R.pass; deny }
        when CCList.is_empty deny
             || not (Access_control_engine.plan_require_all_dirspace_access access_control) ->
          Abb.Future.return (Ok state)
      | Ok { Terrat_access_control.R.deny; _ } ->
          let open Abbs_future_combinators.Infix_result_monad in
          Abbs_future_combinators.Infix_result_app.(
            (fun client pull_request -> (client, pull_request))
            <$> Dv.client ctx state
            <*> Dv.pull_request ctx state)
          >>= fun (client, pull_request) ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Access_control_denied
               (Access_control_engine.policy_branch access_control, `Dirspaces deny))
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | Error `Error ->
          let open Abbs_future_combinators.Infix_result_monad in
          Abbs_future_combinators.Infix_result_app.(
            (fun client pull_request -> (client, pull_request))
            <$> Dv.client ctx state
            <*> Dv.pull_request ctx state)
          >>= fun (client, pull_request) ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Access_control_denied
               (Access_control_engine.policy_branch access_control, `Lookup_err))
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | Error ((#Repo_config.fetch_err | #Terrat_change_match3.synthesize_config_err) as err) ->
          Abb.Future.return (Error err)

    let check_merge_conflict ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.pull_request ctx state
      >>= fun pull_request ->
      match S.Pull_request.state pull_request with
      | Terrat_pull_request.State.(Open Open_status.Merge_conflict) ->
          Logs.info (fun m -> m "EVALUATOR : %s : MERGE_CONFLICT" state.State.request_id);
          Dv.client ctx state
          >>= fun client ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            Msg.Pull_request_not_mergeable
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | Terrat_pull_request.State.Open _
      | Terrat_pull_request.State.Closed
      | Terrat_pull_request.State.Merged _ -> Abb.Future.return (Ok state)

    let check_conflicting_work_manifests op ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.pull_request ctx state
      >>= fun pull_request ->
      Dv.access_control_results ctx state op
      >>= fun { Terrat_access_control.R.pass = passed_dirspaces; _ } ->
      let dirspaces =
        CCList.map
          (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } -> dirspace)
          passed_dirspaces
      in
      let unified_op =
        match op with
        | `Plan -> `Plan
        | `Apply | `Apply_autoapprove | `Apply_force -> `Apply
      in
      query_conflicting_work_manifests_in_repo
        state.State.request_id
        ctx.Ctx.storage
        pull_request
        dirspaces
        unified_op
      >>= function
      | None -> Abb.Future.return (Ok state)
      | Some (Conflicting_work_manifests.Conflicting wms) ->
          Dv.client ctx state
          >>= fun client ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Conflicting_work_manifests wms)
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | Some (Conflicting_work_manifests.Maybe_stale wms) ->
          (* Stale operations will still be queued but we will inform the user
             that there is something up. *)
          Dv.client ctx state
          >>= fun client ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Maybe_stale_work_manifests wms)
          >>= fun () -> Abb.Future.return (Ok state)

    let run_plan_work_manifest_iter =
      H.eval_work_manifest_iter
        ~name:"PLAN"
        ~create:(H.run_op_work_manifest_iter_create `Plan)
        ~update:(H.run_op_work_manifest_iter_update `Plan)
        ~run_success:(H.run_op_work_manifest_iter_run_success `Plan)
        ~run_failure:H.run_op_work_manifest_iter_run_failure
        ~initiate:H.run_op_work_manifest_iter_initiate
        ~result:(H.run_op_work_manifest_iter_result `Plan)
        ~fallthrough:
          (H.eval_plan_work_manifest_iter
             ~store:H.run_op_work_manifest_plan_iter_store
             ~fetch:H.run_op_work_manifest_plan_iter_fetch
             ~fallthrough:H.log_state_err_iter)

    let check_access_control_apply op ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.apply_requirements ctx state
      >>= fun apply_requirements ->
      let access_control_run_type =
        match op with
        | `Apply ->
            `Apply
              (CCList.filter_map
                 (fun { Terrat_pull_request_review.user; _ } -> user)
                 (S.Apply_requirements.approved_reviews apply_requirements))
        | (`Apply_autoapprove | `Apply_force) as op -> op
      in
      Abbs_future_combinators.Infix_result_app.(
        (fun access_control matches client pull_request access_control_result ->
          (access_control, matches, client, pull_request, access_control_result))
        <$> Dv.access_control ctx state
        <*> Dv.matches ctx state op
        <*> Dv.client ctx state
        <*> Dv.pull_request ctx state
        <*> Dv.tf_operation_access_control_evaluation ctx state access_control_run_type)
      >>= fun (access_control, matches, client, pull_request, access_control_result) ->
      let passed_apply_requirements = S.Apply_requirements.passed apply_requirements in
      match access_control_result with
      | _ when not passed_apply_requirements ->
          Logs.info (fun m -> m "EVALUATOR : %s : PR_NOT_APPLIABLE" state.State.request_id);
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Pull_request_not_appliable (pull_request, apply_requirements))
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | { Terrat_access_control.R.pass = []; deny = _ :: _ as deny }
        when not (Access_control_engine.apply_require_all_dirspace_access access_control) ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Access_control_denied
               (Access_control_engine.policy_branch access_control, `All_dirspaces deny))
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | { Terrat_access_control.R.pass; deny }
        when CCList.is_empty deny
             || not (Access_control_engine.apply_require_all_dirspace_access access_control) ->
          Abb.Future.return (Ok state)
      | { Terrat_access_control.R.deny; _ } ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Access_control_denied
               (Access_control_engine.policy_branch access_control, `Dirspaces deny))
          >>= fun () -> Abb.Future.return (Error (`Noop state))

    let check_non_empty_matches_apply op ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.access_control_results ctx state op
      >>= fun { Terrat_access_control.R.pass = working_set_matches; _ } ->
      let trigger_type = Event.trigger_type state.State.event in
      match (working_set_matches, trigger_type) with
      | [], `Auto ->
          Logs.info (fun m ->
              m "EVALUATOR : %s : NOOP : AUTOAPPLY_NO_MATCHES" state.State.request_id);
          Abb.Future.return (Error (`Noop state))
      | [], _ ->
          Logs.info (fun m ->
              m "EVALUATOR : %s : NOOP : APPLY_NO_MATCHING_DIRSPACES" state.State.request_id);
          Dv.client ctx state
          >>= fun client ->
          Dv.pull_request ctx state
          >>= fun pull_request ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            Msg.Apply_no_matching_dirspaces
          >>= fun () -> Abb.Future.return (Error (`Noop state))
      | _ :: _, _ -> Abb.Future.return (Ok state)

    let check_dirspaces_owned_by_other_pull_requests op ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun repo_config pull_request matches -> (repo_config, pull_request, matches))
        <$> Dv.repo_config ctx state
        <*> Dv.pull_request ctx state
        <*> Dv.matches ctx state op)
      >>= fun (repo_config, pull_request, matches) ->
      Abb.Future.return
        (H.dirspaceflows_of_changes repo_config (CCList.flatten matches.Dv.Matches.all_matches))
      >>= fun all_match_dirspaceflows ->
      query_dirspaces_owned_by_other_pull_requests
        state.State.request_id
        ctx.Ctx.storage
        pull_request
        (CCList.map Terrat_change.Dirspaceflow.to_dirspace all_match_dirspaceflows)
      >>= function
      | [] -> Abb.Future.return (Ok state)
      | owned_dirspaces ->
          Dv.client ctx state
          >>= fun client ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Dirspaces_owned_by_other_pull_request owned_dirspaces)
          >>= fun () -> Abb.Future.return (Error (`Noop state))

    let check_dirspaces_missing_plans op ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.pull_request ctx state
      >>= fun pull_request ->
      Dv.access_control_results ctx state op
      >>= fun { Terrat_access_control.R.pass = working_set_matches; _ } ->
      query_dirspaces_without_valid_plans
        state.State.request_id
        ctx.Ctx.storage
        pull_request
        (CCList.map
           (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } -> dirspace)
           working_set_matches)
      >>= function
      | [] -> Abb.Future.return (Ok state)
      | dirspaces ->
          Dv.client ctx state
          >>= fun client ->
          publish_msg
            state.State.request_id
            client
            (Event.user state.State.event)
            pull_request
            (Msg.Missing_plans dirspaces)
          >>= fun () -> Abb.Future.return (Error (`Noop state))

    let run_apply_work_manifest_iter op =
      H.eval_work_manifest_iter
        ~name:"APPLY"
        ~create:(H.run_op_work_manifest_iter_create op)
        ~update:(H.run_op_work_manifest_iter_update op)
        ~run_success:(H.run_op_work_manifest_iter_run_success op)
        ~run_failure:H.run_op_work_manifest_iter_run_failure
        ~initiate:H.run_op_work_manifest_iter_initiate
        ~result:(H.run_op_work_manifest_iter_result op)
        ~fallthrough:
          (H.eval_plan_work_manifest_iter
             ~store:H.run_op_work_manifest_plan_iter_store
             ~fetch:H.run_op_work_manifest_plan_iter_fetch
             ~fallthrough:H.log_state_err_iter)

    let check_all_dirspaces_applied op ctx state =
      let automerge_config = Terrat_base_repo_config_v1.automerge in
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.matches ctx state op
      >>= fun matches ->
      match (state.State.work_manifest_id, matches.Dv.Matches.all_unapplied_matches) with
      | Some work_manifest_id, [] -> (
          query_work_manifest state.State.request_id ctx.Ctx.storage work_manifest_id
          >>= function
          | Some work_manifest ->
              Logs.info (fun m ->
                  m
                    "EVALUATOR : %s : ALL_DIRSPACES_APPLIED : id=%a"
                    state.State.request_id
                    Uuidm.pp
                    work_manifest_id);
              Dv.client ctx state
              >>= fun client ->
              Dv.pull_request ctx state
              >>= fun pull_request ->
              let check =
                S.make_commit_check
                  ~config:ctx.Ctx.config
                  ~description:"Completed"
                  ~title:"terrateam apply"
                  ~status:Terrat_commit_check.Status.Completed
                  ~work_manifest
                  ~repo:(Event.repo state.State.event)
                  (Event.account state.State.event)
              in
              create_commit_checks
                state.State.request_id
                client
                (S.Pull_request.repo pull_request)
                (S.Pull_request.branch_ref pull_request)
                [ check ]
              >>= fun () ->
              Dv.repo_config ctx state
              >>= fun repo_config ->
              let module Am = Terrat_base_repo_config_v1.Automerge in
              let { Am.enabled; delete_branch } = automerge_config repo_config in
              if enabled then
                merge_pull_request state.State.request_id client pull_request
                >>= fun () ->
                if delete_branch then
                  let open Abb.Future.Infix_monad in
                  (* Nothing to do if this fails and it can fail for a few valid
                     reasons, so just ignore. *)
                  delete_pull_request_branch state.State.request_id client pull_request
                  >>= fun _ -> Abb.Future.return (Ok state)
                else Abb.Future.return (Ok state)
              else Abb.Future.return (Ok state)
          | None -> assert false)
      | Some work_manifest_id, unapplied_dirspaces ->
          let module Dsc = Terrat_change_match3.Dirspace_config in
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : UNAPPLIED_DIRSPACES : id=%a : dirspaces=%s"
                state.State.request_id
                Uuidm.pp
                work_manifest_id
                (CCString.concat
                   " "
                   (CCList.map
                      (fun { Dsc.dirspace = { Terrat_dirspace.dir; workspace }; _ } ->
                        dir ^ ":" ^ workspace)
                      (CCList.flatten unapplied_dirspaces))));
          Abb.Future.return (Ok state)
      | None, _ -> assert false

    let recover_noop_complete_work_manifest ctx state =
      match state.State.work_manifest_id with
      | None -> Abb.Future.return (Ok state)
      | Some _ -> complete_work_manifest ctx state

    let update_drift_schedule ctx state =
      let module V1 = Terrat_base_repo_config_v1 in
      let module D = Terrat_base_repo_config_v1.Drift in
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.repo_config ctx state
      >>= fun repo_config ->
      let { D.enabled; schedule; reconcile; tag_query } = V1.drift repo_config in
      Logs.info (fun m ->
          m
            "EVALUATOR : %s : DRIFT : enabled=%s : repo=%s : schedule=%s : reconcile=%s : \
             tag_query=%s"
            state.State.request_id
            (Bool.to_string enabled)
            (S.Repo.to_string (Event.repo state.State.event))
            (D.Schedule.to_string schedule)
            (Bool.to_string reconcile)
            (Terrat_tag_query.to_string tag_query));
      store_drift_schedule
        state.State.request_id
        ctx.Ctx.storage
        (Event.repo state.State.event)
        (V1.drift repo_config)
      >>= fun () -> Abb.Future.return (Ok state)

    let create_drift_events ctx state =
      match state.State.st with
      | State.St.Initial -> (
          let module V1 = Terrat_base_repo_config_v1 in
          let module D = V1.Drift in
          let module Wm = Terrat_work_manifest3 in
          let open Abbs_future_combinators.Infix_result_monad in
          query_missing_drift_scheduled_runs state.State.request_id ctx.Ctx.storage
          >>= function
          | [] -> Abb.Future.return (Error (`Noop state))
          | self :: needed_runs ->
              let f (account, repo) =
                let request_id = Uuidm.to_string (Uuidm.v `V4) in
                Logs.info (fun m ->
                    m
                      "EVALUATOR : %s : DRIFT : request_id=%s : account=%s : repo=%s"
                      state.State.request_id
                      request_id
                      (S.Account.to_string account)
                      (S.Repo.to_string repo));
                {
                  state with
                  State.st = State.St.Resume;
                  request_id;
                  event = Event.Run_drift { account; repo };
                }
              in
              let states = CCList.map f needed_runs in
              let state = f self in
              Abb.Future.return (Error (`Clone (state, states))))
      | State.St.Resume -> Abb.Future.return (Ok { state with State.st = State.St.Initial })
      | _ ->
          H.log_state_err
            state.State.request_id
            state.State.st
            state.State.input
            state.State.work_manifest_id;
          Abb.Future.return (Error `Failure)

    let run_drift_work_manifest_iter = run_plan_work_manifest_iter
    let run_drift_reconcile_work_manifest_iter = run_apply_work_manifest_iter `Apply

    let check_reconcile ctx state =
      let module V1 = Terrat_base_repo_config_v1 in
      let module D = V1.Drift in
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.repo_config ctx state
      >>= fun repo_config ->
      match V1.drift repo_config with
      | { D.reconcile = true; _ } -> Abb.Future.return (Ok state)
      | { D.reconcile = false; _ } -> Abb.Future.return (Error (`Noop state))

    let test_config_build_required ctx state =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.repo_config ctx state
      >>= fun repo_config ->
      let module V1 = Terrat_base_repo_config_v1 in
      let config_builder = V1.config_builder repo_config in
      if config_builder.V1.Config_builder.enabled then
        Dv.query_built_config ctx state
        >>= function
        | Some _ -> Abb.Future.return (Ok (Id.Config_build_not_required, state))
        | None -> Abb.Future.return (Ok (Id.Config_build_required, state))
      else Abb.Future.return (Ok (Id.Config_build_not_required, state))

    let run_config_builder_work_manifest_iter =
      H.eval_work_manifest_iter
        ~name:"CONFIG_BUILDER"
        ~create:(fun ctx state ->
          let module Wm = Terrat_work_manifest3 in
          let open Abbs_future_combinators.Infix_result_monad in
          let account = Event.account state.State.event in
          let repo = Event.repo state.State.event in
          Dv.client ctx state
          >>= fun client ->
          Dv.base_ref ctx state
          >>= fun base_ref' ->
          Dv.working_branch_ref ctx state
          >>= fun working_branch_ref' ->
          Dv.target ctx state
          >>= fun target ->
          let work_manifest =
            {
              Wm.account;
              base_ref = S.Ref.to_string base_ref';
              branch_ref = S.Ref.to_string working_branch_ref';
              changes = [];
              completed_at = None;
              created_at = ();
              denied_dirspaces = [];
              environment = None;
              id = ();
              initiator = Event.initiator state.State.event;
              run_id = ();
              state = ();
              steps = [ Wm.Step.Build_config ];
              tag_query = Terrat_tag_query.any;
              target;
            }
          in
          create_work_manifest state.State.request_id ctx.Ctx.storage work_manifest
          >>= fun work_manifest ->
          H.run_interactive ctx state (fun () ->
              let module Status = Terrat_commit_check.Status in
              Dv.branch_ref ctx state
              >>= fun branch_ref' ->
              let check =
                S.make_commit_check
                  ~config:ctx.Ctx.config
                  ~description:"Queued"
                  ~title:"terrateam build-config"
                  ~status:Status.Queued
                  ~work_manifest
                  ~repo
                  account
              in
              create_commit_checks state.State.request_id client repo branch_ref' [ check ])
          >>= fun () ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : CREATED_WORK_MANIFEST : id=%a : base_ref=%s : branch_ref=%s"
                state.State.request_id
                Uuidm.pp
                work_manifest.Wm.id
                (S.Ref.to_string base_ref')
                (S.Ref.to_string working_branch_ref'));
          Abb.Future.return (Ok [ work_manifest ]))
        ~update:(fun ctx state work_manifest -> raise (Failure "nyi"))
        ~run_success:(fun ctx state work_manifest ->
          H.run_interactive ctx state (fun () ->
              let open Abbs_future_combinators.Infix_result_monad in
              let account = Event.account state.State.event in
              let repo = Event.repo state.State.event in
              Dv.client ctx state
              >>= fun client ->
              Dv.pull_request ctx state
              >>= fun pull_request ->
              let module Status = Terrat_commit_check.Status in
              let check =
                S.make_commit_check
                  ~config:ctx.Ctx.config
                  ~description:"Running"
                  ~title:"terrateam build-config"
                  ~status:Status.Running
                  ~work_manifest
                  ~repo
                  account
              in
              create_commit_checks
                state.State.request_id
                client
                repo
                (S.Pull_request.branch_ref pull_request)
                [ check ]
              >>= fun () -> Abb.Future.return (Ok ())))
        ~run_failure:(fun ctx state err work_manifest ->
          let open Abbs_future_combinators.Infix_result_monad in
          H.run_interactive ctx state (fun () ->
              let account = Event.account state.State.event in
              let repo = Event.repo state.State.event in
              Dv.client ctx state
              >>= fun client ->
              Dv.pull_request ctx state
              >>= fun pull_request ->
              let module Status = Terrat_commit_check.Status in
              let check =
                S.make_commit_check
                  ~config:ctx.Ctx.config
                  ~description:"Failed"
                  ~title:"terrateam build-config"
                  ~status:Status.Failed
                  ~work_manifest
                  ~repo
                  account
              in
              create_commit_checks
                state.State.request_id
                client
                repo
                (S.Pull_request.branch_ref pull_request)
                [ check ]
              >>= fun () ->
              H.publish_run_failure
                state.State.request_id
                client
                (Event.user state.State.event)
                pull_request
                err
              >>= fun () -> Abb.Future.return (Error `Failure))
          >>= fun () -> Abb.Future.return (Error `Failure))
        ~initiate:(fun ctx state encryption_key run_id sha work_manifest ->
          let module Wm = Terrat_work_manifest3 in
          let open Abbs_future_combinators.Infix_result_monad in
          H.initiate_work_manifest
            state
            state.State.request_id
            ctx.Ctx.storage
            run_id
            sha
            work_manifest
          >>= function
          | Some { Wm.id; branch_ref; base_ref; state = Wm.State.(Queued | Running); _ } ->
              Dv.base_ref ctx state
              >>= fun base_ref' ->
              Dv.repo_config ctx state
              >>= fun repo_config ->
              Dv.repo_tree_branch ctx state
              >>= fun repo_tree ->
              Dv.query_index ctx state
              >>= fun index ->
              Dv.base_branch_name ctx state
              >>= fun base_branch_name ->
              Dv.branch_name ctx state
              >>= fun branch_name ->
              let repo_config =
                Terrat_base_repo_config_v1.derive
                  ~ctx:
                    (Terrat_base_repo_config_v1.Ctx.make
                       ~dest_branch:(S.Ref.to_string base_branch_name)
                       ~branch:(S.Ref.to_string branch_name)
                       ())
                  ~index:
                    (CCOption.map_or
                       ~default:Terrat_base_repo_config_v1.Index.empty
                       (fun { Index.index; _ } -> index)
                       index)
                  ~file_list:repo_tree
                  repo_config
              in
              let module B = Terrat_api_components.Work_manifest_build_config in
              let config =
                repo_config
                |> Terrat_base_repo_config_v1.to_version_1
                |> Terrat_repo_config.Version_1.to_yojson
              in
              let response =
                Terrat_api_components.Work_manifest.Work_manifest_build_config
                  {
                    B.base_ref = S.Ref.to_string base_ref';
                    token = H.token encryption_key id;
                    type_ = "build-config";
                    config;
                  }
              in
              Abb.Future.return (Ok (Some response))
          | Some _ | None -> Abb.Future.return (Ok None))
        ~result:(fun ctx state result work_manifest ->
          let module Wm = Terrat_work_manifest3 in
          let module Wmr = Terrat_api_components.Work_manifest_result in
          let module Bc = Terrat_api_components.Work_manifest_build_config_result in
          let module Bcs = Terrat_api_components.Work_manifest_build_config_result_success in
          let module Bcf = Terrat_api_components.Work_manifest_build_config_result_failure in
          let open Abbs_future_combinators.Infix_result_monad in
          let fail msg =
            H.run_interactive ctx state (fun () ->
                let account = Event.account state.State.event in
                let repo = Event.repo state.State.event in
                Dv.client ctx state
                >>= fun client ->
                Dv.pull_request ctx state
                >>= fun pull_request ->
                let module Status = Terrat_commit_check.Status in
                let check =
                  S.make_commit_check
                    ~config:ctx.Ctx.config
                    ~description:"Failed"
                    ~title:"terrateam build-config"
                    ~status:Status.Failed
                    ~work_manifest
                    ~repo
                    account
                in
                create_commit_checks
                  state.State.request_id
                  client
                  repo
                  (S.Pull_request.branch_ref pull_request)
                  [ check ]
                >>= fun () ->
                publish_msg
                  state.State.request_id
                  client
                  (Event.user state.State.event)
                  pull_request
                  msg)
          in
          match result with
          | Wmr.Work_manifest_build_config_result
              (Bc.Work_manifest_build_config_result_success { Bcs.config }) -> (
              let open Abb.Future.Infix_monad in
              Repo_config.repo_config_of_json config
              >>= function
              | Ok _ ->
                  let open Abbs_future_combinators.Infix_result_monad in
                  let account = Event.account state.State.event in
                  Dv.working_branch_ref ctx state
                  >>= fun working_branch_ref' ->
                  store_repo_config_json
                    state.State.request_id
                    ctx.Ctx.storage
                    account
                    working_branch_ref'
                    config
                  >>= fun () ->
                  H.run_interactive ctx state (fun () ->
                      let account = Event.account state.State.event in
                      let repo = Event.repo state.State.event in
                      Dv.client ctx state
                      >>= fun client ->
                      Dv.pull_request ctx state
                      >>= fun pull_request ->
                      let module Status = Terrat_commit_check.Status in
                      let check =
                        S.make_commit_check
                          ~config:ctx.Ctx.config
                          ~description:"Completed"
                          ~title:"terrateam build-config"
                          ~status:Status.Completed
                          ~work_manifest
                          ~repo
                          account
                      in
                      create_commit_checks
                        state.State.request_id
                        client
                        repo
                        (S.Pull_request.branch_ref pull_request)
                        [ check ])
                  >>= fun () -> Abb.Future.return (Ok ())
              | Error (#Terrat_base_repo_config_v1.of_version_1_err as err) ->
                  let open Abbs_future_combinators.Infix_result_monad in
                  fail (Msg.Build_config_err err)
                  >>= fun () -> Abb.Future.return (Error (`Noop state))
              | Error (`Repo_config_parse_err msg) ->
                  let open Abbs_future_combinators.Infix_result_monad in
                  fail (Msg.Build_config_failure msg)
                  >>= fun () -> Abb.Future.return (Error (`Noop state)))
          | Wmr.Work_manifest_build_config_result
              (Bc.Work_manifest_build_config_result_failure { Bcf.msg }) ->
              let open Abbs_future_combinators.Infix_result_monad in
              fail (Msg.Build_config_failure msg)
              >>= fun () -> Abb.Future.return (Error (`Noop state))
          | Terrat_api_components_work_manifest_result.Work_manifest_tf_operation_result _ ->
              assert false
          | Terrat_api_components_work_manifest_result.Work_manifest_tf_operation_result2 _ ->
              assert false
          | Terrat_api_components_work_manifest_result.Work_manifest_index_result _ -> assert false)
        ~fallthrough:H.log_state_err_iter
  end

  let maybe_publish_msg ctx state msg =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Dv.client ctx state
      >>= fun client ->
      Dv.pull_request_safe ctx state
      >>= function
      | Some pull_request ->
          publish_msg state.State.request_id client (Event.user state.State.event) pull_request msg
      | None -> Abb.Future.return (Ok ())
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok () -> Abb.Future.return ()
    | Error `Error ->
        Logs.err (fun m -> m "EVALUATOR : %s : MAYBE_PUBLISH_MSG" state.State.request_id);
        Abb.Future.return ()

  let eval_step step ctx state =
    let open Abb.Future.Infix_monad in
    match state.State.input with
    | Some State.Io.I.Checkpointed -> Abb.Future.return (`Success { state with State.input = None })
    | _ -> (
        step ctx state
        >>= function
        | Ok state -> Abb.Future.return (`Success state)
        | Error (`Yield _ as r) -> Abb.Future.return r
        | Error (`Noop _ as r) -> Abb.Future.return (`Failure r)
        | Error (`Clone (state, v)) ->
            Abb.Future.return (`Yield { state with State.output = Some (State.Io.O.Clone v) })
        | Error (`Checkpoint state) ->
            Abb.Future.return (`Yield { state with State.output = Some State.Io.O.Checkpoint })
        | Error (`Bad_glob_err s) ->
            maybe_publish_msg ctx state (Msg.Bad_glob s)
            >>= fun () -> Abb.Future.return (`Failure `Error)
        | Error (`Depends_on_cycle_err cycle) ->
            maybe_publish_msg ctx state (Msg.Depends_on_cycle cycle)
            >>= fun () -> Abb.Future.return (`Failure `Error)
        | Error (#Terrat_base_repo_config_v1.of_version_1_err as err) ->
            Logs.err (fun m ->
                m
                  "EVALUATOR : %s : ERROR : %a"
                  state.State.request_id
                  Terrat_base_repo_config_v1.pp_of_version_1_err
                  err);
            maybe_publish_msg ctx state (Msg.Repo_config_err err)
            >>= fun () -> Abb.Future.return (`Failure `Error)
        | Error
            ( `Json_decode_err (fname, err)
            | `Yaml_decode_err (fname, err)
            | `Repo_config_parse_err (fname, err) ) ->
            maybe_publish_msg ctx state (Msg.Repo_config_parse_failure (fname, err))
            >>= fun () -> Abb.Future.return (`Failure `Error)
        | Error (#Repo_config.fetch_err as err) ->
            Logs.err (fun m ->
                m "EVALUATOR : %s : ERROR : %a" state.State.request_id Repo_config.pp_fetch_err err);
            maybe_publish_msg ctx state Msg.Unexpected_temporary_err
            >>= fun () -> Abb.Future.return (`Failure `Error)
        | Error (`Ref_mismatch_err state) ->
            maybe_publish_msg ctx state Msg.Mismatched_refs
            >>= fun () -> Abb.Future.return (`Failure (`Noop state))
        | Error `Failure ->
            Logs.err (fun m -> m "EVALUATOR : %s : ERROR : FAILURE" state.State.request_id);
            Abb.Future.return (`Failure `Error)
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "EVALUATOR : %s : ERROR : %a" state.State.request_id Pgsql_io.pp_err err);
            Abb.Future.return (`Failure `Error))

  (* Flow start *)
  let flow =
    let account_status_flow =
      Flow.Flow.(
        choice
          ~id:Id.Test_account_status
          ~f:F.test_account_status
          [
            (Id.Account_enabled, action []);
            (Id.Account_expired, action []);
            ( Id.Account_disabled,
              action [ Flow.Step.make ~id:Id.Account_disabled ~f:(eval_step F.account_disabled) () ]
            );
          ])
    in
    let enabled_flow =
      Flow.Flow.(
        action
          [
            Flow.Step.make
              ~id:Id.Check_enabled_in_repo_config
              ~f:(eval_step F.check_enabled_in_repo_config)
              ();
            Flow.Step.make ~id:Id.React_to_comment ~f:(eval_step F.react_to_comment) ();
          ])
    in
    let recover_noop_flow =
      Flow.Flow.(
        action
          [
            Flow.Step.make
              ~id:Id.Complete_work_manifest
              ~f:(eval_step F.recover_noop_complete_work_manifest)
              ();
          ])
    in
    let complete_work_manifest_flow =
      Flow.Flow.(
        action
          [
            Flow.Step.make ~id:Id.Complete_work_manifest ~f:(eval_step F.complete_work_manifest) ();
          ])
    in
    let store_pull_request_flow =
      Flow.Flow.(
        action [ Flow.Step.make ~id:Id.Store_pull_request ~f:(eval_step F.store_pull_request) () ])
    in
    let config_builder_flow =
      Flow.Flow.(
        choice
          ~id:Id.Test_config_build_required
          ~f:F.test_config_build_required
          [
            ( Id.Config_build_required,
              action
                [
                  Flow.Step.make
                    ~id:Id.Run_work_manifest_iter
                    ~f:(eval_step F.run_config_builder_work_manifest_iter)
                    ();
                ] );
            (Id.Config_build_not_required, action []);
          ])
    in
    let index_flow =
      Flow.Flow.(
        seq
          config_builder_flow
          (choice
             ~id:Id.Test_index_required
             ~f:F.test_index_required
             [
               ( Id.Index_required,
                 action
                   [
                     Flow.Step.make
                       ~id:Id.Run_work_manifest_iter
                       ~f:(eval_step F.run_index_work_manifest_iter)
                       ();
                   ] );
               (Id.Index_not_required, action []);
             ]))
    in
    let event_kind_op_flow =
      let op_kind_plan_flow =
        Flow.Flow.(
          seq
            (action
               [
                 Flow.Step.make
                   ~id:Id.Check_pull_request_state
                   ~f:(eval_step F.check_pull_request_state)
                   ();
               ])
            (seq
               index_flow
               (action
                  [
                    Flow.Step.make
                      ~id:Id.Check_access_control_ci_change
                      ~f:(eval_step F.check_access_control_ci_change)
                      ();
                    Flow.Step.make
                      ~id:Id.Check_access_control_files
                      ~f:(eval_step F.check_access_control_files)
                      ();
                    Flow.Step.make
                      ~id:Id.Check_access_control_repo_config
                      ~f:(eval_step F.check_access_control_repo_config)
                      ();
                    Flow.Step.make
                      ~id:Id.Check_valid_destination_branch
                      ~f:(eval_step F.check_valid_destination_branch)
                      ();
                    Flow.Step.make
                      ~id:Id.Check_access_control_plan
                      ~f:(eval_step F.check_access_control_plan)
                      ();
                    Flow.Step.make
                      ~id:Id.Check_non_empty_matches
                      ~f:(eval_step F.check_non_empty_matches)
                      ();
                    Flow.Step.make
                      ~id:Id.Check_account_status_expired
                      ~f:(eval_step F.check_account_status_expired)
                      ();
                    Flow.Step.make
                      ~id:Id.Check_merge_conflict
                      ~f:(eval_step F.check_merge_conflict)
                      ();
                    Flow.Step.make
                      ~id:Id.Check_conflicting_work_manifests
                      ~f:(eval_step (F.check_conflicting_work_manifests `Plan))
                      ();
                    Flow.Step.make
                      ~id:Id.Run_work_manifest_iter
                      ~f:(eval_step F.run_plan_work_manifest_iter)
                      ();
                    Flow.Step.make
                      ~id:Id.Complete_work_manifest
                      ~f:(eval_step F.complete_work_manifest)
                      ();
                  ])))
      in
      let op_kind_apply_flow op =
        Flow.Flow.(
          action
            [
              Flow.Step.make
                ~id:Id.Check_pull_request_state
                ~f:(eval_step F.check_pull_request_state)
                ();
              Flow.Step.make
                ~id:Id.Check_access_control_ci_change
                ~f:(eval_step F.check_access_control_ci_change)
                ();
              Flow.Step.make
                ~id:Id.Check_access_control_files
                ~f:(eval_step F.check_access_control_files)
                ();
              Flow.Step.make
                ~id:Id.Check_access_control_repo_config
                ~f:(eval_step F.check_access_control_repo_config)
                ();
              Flow.Step.make
                ~id:Id.Check_access_control_apply
                ~f:(eval_step (F.check_access_control_apply op))
                ();
              Flow.Step.make
                ~id:Id.Check_conflicting_work_manifests
                ~f:(eval_step (F.check_conflicting_work_manifests op))
                ();
              Flow.Step.make
                ~id:Id.Check_non_empty_matches
                ~f:(eval_step (F.check_non_empty_matches_apply op))
                ();
              Flow.Step.make
                ~id:Id.Check_account_status_expired
                ~f:(eval_step F.check_account_status_expired)
                ();
              Flow.Step.make
                ~id:Id.Check_dirspaces_owned_by_other_pull_requests
                ~f:(eval_step (F.check_dirspaces_owned_by_other_pull_requests op))
                ();
              Flow.Step.make
                ~id:Id.Check_dirspaces_missing_plans
                ~f:(eval_step (F.check_dirspaces_missing_plans op))
                ();
              Flow.Step.make
                ~id:Id.Run_work_manifest_iter
                ~f:(eval_step (F.run_apply_work_manifest_iter op))
                ();
              Flow.Step.make
                ~id:Id.Complete_work_manifest
                ~f:(eval_step F.complete_work_manifest)
                ();
              Flow.Step.make
                ~id:Id.Check_all_dirspaces_applied
                ~f:(eval_step (F.check_all_dirspaces_applied op))
                ();
            ])
      in
      Flow.Flow.(
        recover
          ~id:Id.Recover
          (finally
             ~id:Id.Always_store_pull_request
             ~finally:store_pull_request_flow
             (seq
                account_status_flow
                (seq
                   enabled_flow
                   (seq
                      store_pull_request_flow
                      (choice
                         ~id:Id.Test_op_kind
                         ~f:F.test_op_kind
                         [
                           (Id.Op_kind_plan, op_kind_plan_flow);
                           (Id.Op_kind_apply, op_kind_apply_flow `Apply);
                           (Id.Op_kind_apply_autoapprove, op_kind_apply_flow `Apply_autoapprove);
                           (Id.Op_kind_apply_force, op_kind_apply_flow `Apply_force);
                         ])))))
          ~f:(fun _ state -> function
            | `Step_err (_, `Noop state) -> Abb.Future.return (Ok (Id.Recover_noop, state))
            | _ -> Abb.Future.return (Error `Error))
          ~recover:[ (Id.Recover_noop, recover_noop_flow) ])
    in
    let event_kind_run_drift_flow =
      Flow.Flow.(
        recover
          ~id:Id.Recover
          (seq
             (action
                [
                  Flow.Step.make ~id:Id.Create_drift_events ~f:(eval_step F.create_drift_events) ();
                ])
             (seq
                account_status_flow
                (seq
                   enabled_flow
                   (seq
                      index_flow
                      (action
                         [
                           Flow.Step.make
                             ~id:Id.Run_work_manifest_iter
                             ~f:(eval_step F.run_drift_work_manifest_iter)
                             ();
                           Flow.Step.make
                             ~id:Id.Complete_work_manifest
                             ~f:(eval_step F.complete_work_manifest)
                             ();
                           Flow.Step.make
                             ~id:Id.Unset_work_manifest_id
                             ~f:
                               (eval_step (fun _ state ->
                                    Abb.Future.return
                                      (Ok { state with State.work_manifest_id = None })))
                             ();
                           Flow.Step.make ~id:Id.Check_reconcile ~f:(eval_step F.check_reconcile) ();
                           Flow.Step.make
                             ~id:Id.Run_work_manifest_iter
                             ~f:(eval_step F.run_drift_reconcile_work_manifest_iter)
                             ();
                           Flow.Step.make
                             ~id:Id.Complete_work_manifest
                             ~f:(eval_step F.complete_work_manifest)
                             ();
                         ])))))
          ~f:(fun _ state -> function
            | `Step_err (_, `Noop state) -> Abb.Future.return (Ok (Id.Recover_noop, state))
            | _ -> Abb.Future.return (Error `Error))
          ~recover:[ (Id.Recover_noop, recover_noop_flow) ])
    in
    let event_kind_push_flow =
      Flow.Flow.(
        seq
          (action
             [
               Flow.Step.make ~id:Id.Update_drift_schedule ~f:(eval_step F.update_drift_schedule) ();
             ])
          event_kind_run_drift_flow)
    in
    let event_kind_repo_config_flow =
      Flow.Flow.(
        seq
          index_flow
          (action
             [
               Flow.Step.make
                 ~id:Id.Complete_work_manifest
                 ~f:(eval_step F.complete_work_manifest)
                 ();
               Flow.Step.make ~id:Id.Publish_repo_config ~f:(eval_step F.publish_repo_config) ();
             ]))
    in
    let event_kind_index_flow =
      Flow.Flow.(
        seq
          (action
             [ Flow.Step.make ~id:Id.Store_pull_request ~f:(eval_step F.store_pull_request) () ])
          (seq
             index_flow
             (seq
                complete_work_manifest_flow
                (action [ Flow.Step.make ~id:Id.Publish_index ~f:(eval_step F.publish_index) () ]))))
    in
    let event_kind_unlock_flow =
      Flow.Flow.(action [ Flow.Step.make ~id:Id.Unlock ~f:(eval_step F.unlock) () ])
    in
    let store_account_repository_flow =
      Flow.Flow.(
        action
          [
            Flow.Step.make
              ~id:Id.Store_account_repository
              ~f:(eval_step F.store_account_repository)
              ();
          ])
    in
    Flow.create
      ~log
      Flow.Flow.(
        seq
          store_account_repository_flow
          (choice
             ~id:Id.Test_event_kind
             ~f:F.test_event_kind
             [
               (Id.Event_kind_op, event_kind_op_flow);
               (Id.Event_kind_push, event_kind_push_flow);
               (Id.Event_kind_run_drift, event_kind_run_drift_flow);
               (Id.Event_kind_repo_config, event_kind_repo_config_flow);
               (Id.Event_kind_index, event_kind_index_flow);
               (Id.Event_kind_unlock, event_kind_unlock_flow);
               ( Id.Event_kind_help,
                 action [ Flow.Step.make ~id:Id.Publish_help ~f:(eval_step F.publish_help) () ] );
               ( Id.Event_kind_feedback,
                 action
                   [ Flow.Step.make ~id:Id.Record_feedback ~f:(eval_step F.record_feedback) () ] );
             ]))
  (* Flow end *)

  module Runner = struct
    let resume_event ctx resume f =
      let state = Flow.Yield.state resume in
      (* We create a new [request_id] for each run of the flow.  Technically
         speaking [request_id] is a legacy name representing where the value
         came from and how it's commonly used but in reality it is used as a
         unique id per run.  Generally a flow is initiated by some external
         event, such as a web request which is where this value comes from.
         However sometimes a [resume] can happen inside of another run, for
         example when emitting a value or running a work manifest.  So we always
         create a new request ID before resuming a run, ensuring it gets a
         unique value. *)
      let request_id' = Uuidm.to_string (Uuidm.v `V4) in
      Abbs_future_combinators.with_finally
        (fun () ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : FLOW : RESUME_START : id=%s : new_request_id=%s"
                ctx.Ctx.request_id
                state.State.request_id
                request_id');
          f ctx resume)
        ~finally:(fun () ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : FLOW : RESUME_END : id=%s : new_request_id=%s"
                ctx.Ctx.request_id
                state.State.request_id
                request_id');
          Abb.Future.return ())

    let rec exec_flow ctx resume' =
      let open Abb.Future.Infix_monad in
      Flow.resume ctx resume' flow
      >>= function
      | (`Success _ | `Failure _) as ret -> Abb.Future.return (Ok ret)
      | `Yield resume' -> (
          let state = Flow.Yield.state resume' in
          match state.State.output with
          | Some (State.Io.O.Clone states) ->
              let open Abb.Future.Infix_monad in
              (* Cloning is used to fan a state out.  The new state's are
                 immediately resumed from where they left off. *)
              Abbs_future_combinators.List.iter
                ~f:(fun state ->
                  let request_id = Uuidm.to_string (Uuidm.v `V4) in
                  Logs.info (fun m ->
                      m "EVALUATOR : %s : CLONE : request_id=%s" state.State.request_id request_id);
                  let state = { state with State.request_id; input = None; output = None } in
                  let resume' = Flow.Yield.set_state state resume' in
                  Abbs_future_combinators.ignore (exec_flow ctx resume'))
                states
              >>= fun () ->
              exec_flow
                ctx
                (Flow.Yield.set_state { state with State.input = None; output = None } resume')
          | Some _ | None -> (
              match state.State.work_manifest_id with
              | Some work_manifest_id ->
                  let open Abbs_future_combinators.Infix_result_monad in
                  let data = Flow.Yield.to_string resume' in
                  store_flow_state ctx.Ctx.request_id ctx.Ctx.storage work_manifest_id data
                  >>= fun () -> Abb.Future.return (Ok (`Yield resume'))
              | None -> Abb.Future.return (Ok (`Yield resume'))))

    let rec run_work_manifests request_id ctx =
      let module Wm = Terrat_work_manifest3 in
      let open Abbs_future_combinators.Infix_result_monad in
      Pgsql_pool.with_conn ctx.Ctx.storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              query_next_pending_work_manifest request_id db
              >>= function
              | Some work_manifest -> (
                  let run =
                    create_client request_id ctx.Ctx.config work_manifest.Wm.account
                    >>= fun client ->
                    run_work_manifest request_id ctx.Ctx.config client work_manifest
                  in
                  let open Abb.Future.Infix_monad in
                  run
                  >>= function
                  | Ok () ->
                      update_work_manifest_state
                        request_id
                        db
                        work_manifest.Wm.id
                        Terrat_work_manifest3.State.Running
                      >>= fun _ ->
                      Abb.Future.fork
                        (notify_work_manifest_run_success request_id ctx work_manifest)
                      >>= fun _ -> Abb.Future.return (Ok `Cont)
                  | Error err ->
                      update_work_manifest_state
                        request_id
                        db
                        work_manifest.Wm.id
                        Terrat_work_manifest3.State.Aborted
                      >>= fun _ ->
                      Abb.Future.fork
                        (notify_work_manifest_run_failure request_id ctx work_manifest err)
                      >>= fun _ -> Abb.Future.return (Ok `Cont))
              | None -> Abb.Future.return (Ok `Done)))
      >>= function
      | `Cont -> run_work_manifests request_id ctx
      | `Done -> Abb.Future.return (Ok ())

    and resume_raw ctx resume_point update =
      let open Abbs_future_combinators.Infix_result_monad in
      Pgsql_pool.with_conn ctx.Ctx.storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              match resume_point with
              | `Work_manifest work_manifest_id -> (
                  query_flow_state ctx.Ctx.request_id db work_manifest_id
                  >>= function
                  | Some str ->
                      Abb.Future.return (Flow.Yield.of_string str)
                      >>= fun resume' ->
                      let state = update (Flow.Yield.state resume') in
                      let resume' = Flow.Yield.set_state state resume' in
                      resume_event { ctx with Ctx.storage = db } resume' exec_flow
                  | None -> Abb.Future.return (Error `Error))
              | `Resume resume' -> resume_event { ctx with Ctx.storage = db } resume' exec_flow))
      >>= function
      | `Success _ ->
          let open Abb.Future.Infix_monad in
          (match resume_point with
          | `Work_manifest work_manifest_id ->
              Pgsql_pool.with_conn ctx.Ctx.storage ~f:(fun db ->
                  delete_flow_state ctx.Ctx.request_id db work_manifest_id)
          | `Resume _ -> Abb.Future.return (Ok ()))
          >>= fun _ -> Abb.Future.return (Ok ())
      | `Failure _ ->
          let open Abb.Future.Infix_monad in
          (match resume_point with
          | `Work_manifest work_manifest_id ->
              Pgsql_pool.with_conn ctx.Ctx.storage ~f:(fun db ->
                  delete_flow_state ctx.Ctx.request_id db work_manifest_id)
          | `Resume _ -> Abb.Future.return (Ok ()))
          >>= fun _ -> Abb.Future.return (Error `Error)
      | `Yield resume' -> (
          let state = Flow.Yield.state resume' in
          match state.State.output with
          | Some State.Io.O.Checkpoint ->
              let state =
                { state with State.input = Some State.Io.I.Checkpointed; output = None }
              in
              let resume' = Flow.Yield.set_state state resume' in
              resume_raw ctx (`Resume resume') CCFun.id
          | _ -> Abb.Future.return (Ok ()))

    and resume ctx work_manifest_id update =
      Abbs_future_combinators.with_finally
        (fun () -> resume_raw ctx (`Work_manifest work_manifest_id) update)
        ~finally:(fun () ->
          Abbs_future_combinators.ignore (run_work_manifests ctx.Ctx.request_id ctx))

    and notify_work_manifest_run_success request_id ctx work_manifest =
      let module Wm = Terrat_work_manifest3 in
      Abbs_future_combinators.ignore
        (resume_raw ctx (`Work_manifest work_manifest.Wm.id) (fun state ->
             { state with State.input = Some State.Io.I.Work_manifest_run_success }))

    and notify_work_manifest_run_failure request_id ctx work_manifest err =
      let module Wm = Terrat_work_manifest3 in
      Abbs_future_combinators.ignore
        (resume_raw ctx (`Work_manifest work_manifest.Wm.id) (fun state ->
             { state with State.input = Some (State.Io.I.Work_manifest_run_failure err) }))

    let run ctx =
      let open Abb.Future.Infix_monad in
      Abb.Future.await_bind
        (function
          | `Det () -> Abb.Future.return ()
          | `Aborted ->
              Logs.info (fun m -> m "EVALUATOR : %s : RUNNER : ABORTED" ctx.Ctx.request_id);
              Abb.Future.return ()
          | `Exn (exn, bt_opt) ->
              Logs.err (fun m ->
                  m
                    "EVALUATOR : %s : RUNNER : %s : %s"
                    ctx.Ctx.request_id
                    (Printexc.to_string exn)
                    (CCOption.map_or ~default:"" Printexc.raw_backtrace_to_string bt_opt));
              Abb.Future.return ())
        (run_work_manifests ctx.Ctx.request_id ctx
        >>= function
        | Ok () -> Abb.Future.return ()
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "EVALUATOR : %s : ERROR : %a" ctx.Ctx.request_id Pgsql_io.pp_err err);
            Abb.Future.return ()
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "EVALUATOR : %s : ERROR : %a" ctx.Ctx.request_id Pgsql_pool.pp_err err);
            Abb.Future.return ()
        | Error `Error -> Abb.Future.return ())
  end

  let log_event state =
    match state.State.event with
    | Event.Pull_request_open { account; user; repo; pull_request_id } ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : EVENT : PULL_REQUEST_OPEN : account=%s : user=%s : repo=%s : \
               pull_number=%d"
              state.State.request_id
              (S.Account.to_string account)
              (S.User.to_string user)
              (S.Repo.to_string repo)
              pull_request_id)
    | Event.Pull_request_close { account; user; repo; pull_request_id } ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : EVENT : PULL_REQUEST_CLOSE : account=%s : user=%s : repo=%s : \
               pull_number=%d"
              state.State.request_id
              (S.Account.to_string account)
              (S.User.to_string user)
              (S.Repo.to_string repo)
              pull_request_id)
    | Event.Pull_request_sync { account; user; repo; pull_request_id } ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : EVENT : PULL_REQUEST_SYNC : account=%s : user=%s : repo=%s : \
               pull_number=%d"
              state.State.request_id
              (S.Account.to_string account)
              (S.User.to_string user)
              (S.Repo.to_string repo)
              pull_request_id)
    | Event.Pull_request_ready_for_review { account; user; repo; pull_request_id } ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : EVENT : PULL_REQUEST_READY_FOR_REVIEW : account=%s : user=%s : \
               repo=%s : pull_number=%d"
              state.State.request_id
              (S.Account.to_string account)
              (S.User.to_string user)
              (S.Repo.to_string repo)
              pull_request_id)
    | Event.Pull_request_comment { account; comment; repo; pull_request_id; comment_id; user } ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : EVENT : PULL_REQUEST_COMMENT : account=%s : user=%s : repo=%s : \
               pull_number=%d : comment_id=%d : comment=%s "
              state.State.request_id
              (S.Account.to_string account)
              (S.User.to_string user)
              (S.Repo.to_string repo)
              pull_request_id
              comment_id
              (Terrat_comment.to_string comment))
    | Event.Push { account; user; repo; branch } ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : EVENT : PUSH : account=%s : user=%s : repo=%s : branch=%s"
              state.State.request_id
              (S.Account.to_string account)
              (S.User.to_string user)
              (S.Repo.to_string repo)
              (S.Ref.to_string branch))
    | Event.Run_scheduled_drift ->
        Logs.info (fun m -> m "EVALUATOR : %s : EVENT : RUN_SCHEDULED_DRIFT" state.State.request_id)
    | Event.Run_drift _ -> assert false

  let run_event ctx event =
    let open Abb.Future.Infix_monad in
    Abb.Future.fork
      (Abbs_future_combinators.with_finally
         (fun () ->
           Logs.info (fun m -> m "EVALUATOR : %s : FLOW : START" ctx.Ctx.request_id);
           let state =
             {
               State.request_id = ctx.Ctx.request_id;
               event;
               work_manifest_id = None;
               st = State.St.Initial;
               input = None;
               output = None;
             }
           in
           log_event state;
           Runner.resume_raw ctx (`Resume (Flow.yield_of_state state)) CCFun.id)
         ~finally:(fun () ->
           Logs.info (fun m -> m "EVALUATOR : %s : FLOW : END" ctx.Ctx.request_id);
           Abbs_future_combinators.ignore (Abb.Future.fork (Runner.run ctx))))
    >>= fun _ -> Abb.Future.return ()

  let resume_work ctx work_manifest_id update =
    Abb.Future.await_bind
      (function
        | `Det r -> Abb.Future.return r
        | `Aborted ->
            Logs.err (fun m -> m "EVALUATOR : %s : RUNNER : ABORTED" ctx.Ctx.request_id);
            Abb.Future.return (Error `Error)
        | `Exn (exn, bt_opt) ->
            Logs.err (fun m ->
                m
                  "EVALUATOR : %s : RUNNER : %s : %s"
                  ctx.Ctx.request_id
                  (Printexc.to_string exn)
                  (CCOption.map_or ~default:"" Printexc.raw_backtrace_to_string bt_opt));
            Abb.Future.return (Error `Error))
      (let open Abb.Future.Infix_monad in
       Abbs_future_combinators.with_finally
         (fun () ->
           Runner.resume ctx work_manifest_id update
           >>= function
           | Ok () -> Abb.Future.return (Ok ())
           | Error (#Pgsql_pool.err as err) ->
               Logs.err (fun m ->
                   m
                     "EVALUATOR : %s : work_manifest_id=%a : %a"
                     ctx.Ctx.request_id
                     Uuidm.pp
                     work_manifest_id
                     Pgsql_pool.pp_err
                     err);
               Abb.Future.return (Error `Error)
           | Error (#Pgsql_io.err as err) ->
               Logs.err (fun m ->
                   m
                     "EVALUATOR : %s : work_manifest_id=%a : %a"
                     ctx.Ctx.request_id
                     Uuidm.pp
                     work_manifest_id
                     Pgsql_io.pp_err
                     err);
               Abb.Future.return (Error `Error)
           | Error (#Flow.Yield.of_string_err as err) ->
               Logs.err (fun m ->
                   m
                     "EVALUATOR : %s : work_manifest_id=%a : %a"
                     ctx.Ctx.request_id
                     Uuidm.pp
                     work_manifest_id
                     Flow.Yield.pp_of_string_err
                     err);
               Abb.Future.return (Error `Error)
           | Error `Error ->
               Logs.err (fun m ->
                   m
                     "EVALUATOR : %s : work_manifest_id=%a : ERROR"
                     ctx.Ctx.request_id
                     Uuidm.pp
                     work_manifest_id);
               Abb.Future.return (Error `Error))
         ~finally:(fun () -> Abbs_future_combinators.ignore (Abb.Future.fork (Runner.run ctx))))

  (* If the flow future finishes first, fail, otherwise return what the flow's
     promise would return. *)
  let first err fut =
    let open Abb.Future.Infix_monad in
    Abbs_future_combinators.first
      (err >>= fun _ -> Abb.Future.return (Error `Error))
      (fut
      >>= function
      | Ok r -> Abb.Future.return (Ok r)
      | Error err -> Abb.Future.return (Error err))
    >>= fun (r, _) -> Abb.Future.return r

  let run_work_manifest_initiate ctx encryption_key work_manifest_id initiate =
    let open Abb.Future.Infix_monad in
    let p = Abb.Future.Promise.create () in
    Abb.Future.fork
      (resume_work ctx work_manifest_id (fun state ->
           Logs.info (fun m ->
               m "EVALUATOR : %s : INITIATE : state=%s" ctx.Ctx.request_id state.State.request_id);
           {
             state with
             State.input = Some (State.Io.I.Work_manifest_initiate { encryption_key; initiate; p });
           }))
    >>= fun fut ->
    (first fut (Abb.Future.Promise.future p)
      : (Terrat_api_components.Work_manifest.t option, [ `Error ]) result Abb.Future.t
      :> (Terrat_api_components.Work_manifest.t option, [> `Error ]) result Abb.Future.t)

  let run_work_manifest_result ctx work_manifest_id result =
    let open Abb.Future.Infix_monad in
    let p = Abb.Future.Promise.create () in
    Abb.Future.fork
      (resume_work ctx work_manifest_id (fun state ->
           Logs.info (fun m ->
               m "EVALUATOR : %s : RESULT : state=%s" ctx.Ctx.request_id state.State.request_id);
           { state with State.input = Some (State.Io.I.Work_manifest_result { result; p }) }))
    >>= fun fut ->
    (first fut (Abb.Future.Promise.future p)
      : (unit, [ `Error ]) result Abb.Future.t
      :> (unit, [> `Error ]) result Abb.Future.t)

  let run_plan_store ctx work_manifest_id plan =
    let module Pc = Terrat_api_components.Plan_create in
    let open Abb.Future.Infix_monad in
    let p = Abb.Future.Promise.create () in
    let { Pc.path; workspace; plan_data; has_changes } = plan in
    let dirspace = { Terrat_dirspace.dir = path; workspace } in
    Abb.Future.fork
      (resume_work ctx work_manifest_id (fun state ->
           Logs.info (fun m ->
               m "EVALUATOR : %s : PLAN_STORE : state=%s" ctx.Ctx.request_id state.State.request_id);
           {
             state with
             State.input =
               Some (State.Io.I.Plan_store { dirspace; data = plan_data; has_changes; p });
           }))
    >>= fun fut ->
    (first fut (Abb.Future.Promise.future p)
      : (unit, [ `Error ]) result Abb.Future.t
      :> (unit, [> `Error ]) result Abb.Future.t)

  let run_plan_fetch ctx work_manifest_id dirspace =
    let open Abb.Future.Infix_monad in
    let p = Abb.Future.Promise.create () in
    Abb.Future.fork
      (resume_work ctx work_manifest_id (fun state ->
           Logs.info (fun m ->
               m "EVALUATOR : %s : PLAN_FETCH : state=%s" ctx.Ctx.request_id state.State.request_id);
           { state with State.input = Some (State.Io.I.Plan_fetch { dirspace; p }) }))
    >>= fun fut ->
    (first fut (Abb.Future.Promise.future p)
      : (string option, [ `Error ]) result Abb.Future.t
      :> (string option, [> `Error ]) result Abb.Future.t)

  let run_work_manifest_failure ctx work_manifest_id =
    let open Abb.Future.Infix_monad in
    let p = Abb.Future.Promise.create () in
    Abb.Future.fork
      (resume_work ctx work_manifest_id (fun state ->
           Logs.info (fun m ->
               m
                 "EVALUATOR : %s : WORK_MANIFEST_FAILURE : state=%s"
                 ctx.Ctx.request_id
                 state.State.request_id);
           { state with State.input = Some (State.Io.I.Work_manifest_failure { p }) }))
    >>= fun fut ->
    (first fut (Abb.Future.Promise.future p)
      : (unit, [ `Error ]) result Abb.Future.t
      :> (unit, [> `Error ]) result Abb.Future.t)

  let run_scheduled_drift ctx =
    Logs.info (fun m -> m "EVALUATOR : %s : SCHEDULED_DRIFT" ctx.Ctx.request_id);
    Abbs_future_combinators.to_result (run_event ctx Event.Run_scheduled_drift)

  let run_plan_cleanup ctx =
    let open Abb.Future.Infix_monad in
    Logs.info (fun m -> m "EVALUATOR : %s : PLAN_CLEANUP" ctx.Ctx.request_id);
    Pgsql_pool.with_conn ctx.Ctx.storage ~f:(fun db -> cleanup_plans ctx.Ctx.request_id db)
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error `Error -> Abb.Future.return (Error `Error)
    | Error (#Pgsql_pool.err as err) ->
        Logs.err (fun m ->
            m "EVALUATOR : %s : PLAN_CLEANUP : %a" ctx.Ctx.request_id Pgsql_pool.pp_err err);
        Abb.Future.return (Error `Error)

  let run_flow_state_cleanup ctx =
    let open Abb.Future.Infix_monad in
    Logs.info (fun m -> m "EVALUATOR : %s : FLOW_STATE_CLEANUP" ctx.Ctx.request_id);
    Pgsql_pool.with_conn ctx.Ctx.storage ~f:(fun db -> cleanup_flow_states ctx.Ctx.request_id db)
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error `Error -> Abb.Future.return (Error `Error)
    | Error (#Pgsql_pool.err as err) ->
        Logs.err (fun m ->
            m "EVALUATOR : %s : FLOW_STATE_CLEANUP : %a" ctx.Ctx.request_id Pgsql_pool.pp_err err);
        Abb.Future.return (Error `Error)

  let run_repo_config_cleanup ctx =
    let open Abb.Future.Infix_monad in
    Logs.info (fun m -> m "EVALUATOR : %s : REPO_CONFIG_CLEANUP" ctx.Ctx.request_id);
    Pgsql_pool.with_conn ctx.Ctx.storage ~f:(fun db -> cleanup_repo_configs ctx.Ctx.request_id db)
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error `Error -> Abb.Future.return (Error `Error)
    | Error (#Pgsql_pool.err as err) ->
        Logs.err (fun m ->
            m "EVALUATOR : %s : REPO_CONFIG_CLEANUP : %a" ctx.Ctx.request_id Pgsql_pool.pp_err err);
        Abb.Future.return (Error `Error)
end
