module Dir_set = CCSet.Make (CCString)
module String_set = CCSet.Make (CCString)
module Dirspace_map = CCMap.Make (Terrat_change.Dirspace)
module Dirspace_set = CCSet.Make (Terrat_change.Dirspace)

module Metrics = struct
  module DefaultHistogram = Prmths.DefaultHistogram

  module Dirspaces_per_work_manifest_histogram = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_list [ 1.0; 5.0; 10.0; 20.0; 50.0; 100.0 ]
  end)

  let namespace = "terrat"
  let subsystem = "evaluator"

  let eval_duration_seconds =
    let help = "Time to evaluate an event" in
    DefaultHistogram.v ~help ~namespace ~subsystem "eval_duration_seconds"

  let stored_work_manifests_total =
    let help = "Number of work manifests stored" in
    Prmths.Counter.v_label
      ~label_name:"run_type"
      ~help
      ~namespace
      ~subsystem
      "stored_work_manifests_total"

  let operations_total =
    let help = "Count of operations per type" in
    Prmths.Counter.v_label ~label_name:"run_type" ~help ~namespace ~subsystem "operations_total"

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

  let aborted_errors_total = Terrat_metrics.errors_total ~m:subsystem ~t:"aborted"
  let exn_errors_total = Terrat_metrics.errors_total ~m:subsystem ~t:"exn"

  let op_on_pull_request_not_mergeable =
    let help = "Count of operations on a pull requests that are not mergeable" in
    Prmths.Counter.v ~help ~namespace ~subsystem "op_on_pull_request_no_mergeable"

  let dirspaces_per_work_manifest =
    let help = "Number of dirspaces per work manifest" in
    Dirspaces_per_work_manifest_histogram.v_label
      ~label_name:"run_type"
      ~help
      ~namespace
      ~subsystem
      "dirspaces_per_work_manifest"

  let op_on_account_disabled_total =
    let help = "Count of operations on a disabled account" in
    Prmths.Counter.v ~help ~namespace ~subsystem "op_on_account_disabled_total"
end

module Unlock_id = struct
  type t =
    | Pull_request of int
    | Drift
  [@@deriving show]
end

module Msg = struct
  type access_control_denied =
    [ `All_dirspaces of Terrat_access_control.R.Deny.t list
    | `Dirspaces of Terrat_access_control.R.Deny.t list
    | `Invalid_query of string
    | `Lookup_err
    | `Terrateam_config_update of string list
    | `Terrateam_config_update_bad_query of string
    | `Unlock of string list
    ]

  type ('pull_request, 'src, 'apply_requirements) t =
    | Access_control_denied of (string * access_control_denied)
    | Account_expired
    | Apply_no_matching_dirspaces
    | Autoapply_running
    | Bad_glob of string
    | Conflicting_work_manifests of 'src Terrat_work_manifest2.Existing.t list
    | Dest_branch_no_match of 'pull_request
    | Dirspaces_owned_by_other_pull_request of (Terrat_change.Dirspace.t * 'pull_request) list
    | Index_complete of (bool * (string * int option * string) list)
    | Missing_plans of Terrat_change.Dirspace.t list
    | Plan_no_matching_dirspaces
    | Pull_request_not_appliable of ('pull_request * 'apply_requirements)
    | Pull_request_not_mergeable
    | Repo_config of (Terrat_repo_config_version_1.t * Terrat_change_match.Dirs.t)
    | Repo_config_failure of string
    | Repo_config_parse_failure of string
    | Tag_query_err of Terrat_tag_query_ast.err
    | Unexpected_temporary_err
    | Unlock_success
end

module Tf_operation = struct
  type tf_mode =
    | Manual
    | Auto
  [@@deriving show]

  type t =
    | Apply of tf_mode
    | Apply_autoapprove
    | Apply_force
    | Plan of tf_mode
  [@@deriving show]

  let to_string = function
    | Apply Auto -> "autoapply"
    | Apply Manual -> "apply"
    | Apply_force -> "apply_force"
    | Apply_autoapprove -> "apply_autoapprove"
    | Plan Auto -> "autoplan"
    | Plan Manual -> "plan"

  let to_run_type =
    let module Rt = Terrat_work_manifest2.Run_type in
    function
    | Apply Auto -> Rt.Autoapply
    | Apply Manual -> Rt.Apply
    | Apply_force -> Rt.Apply
    | Apply_autoapprove -> Rt.Unsafe_apply
    | Plan Auto -> Rt.Autoplan
    | Plan Manual -> Rt.Plan

  let of_run_type =
    let module Rt = Terrat_work_manifest2.Run_type in
    function
    | Rt.Apply -> Apply Manual
    | Rt.Autoapply -> Apply Auto
    | Rt.Autoplan -> Plan Auto
    | Rt.Plan -> Plan Manual
    | Rt.Unsafe_apply -> Apply_autoapprove
end

module Result_status = struct
  type t = {
    dirspaces : (Terrat_change.Dirspace.t * bool) list;
    overall : bool;
    post_hooks : bool;
    pre_hooks : bool;
  }
  [@@deriving show]
end

let compute_matches ~repo_config ~tag_query ~out_of_change_applies ~diff ~repo_tree ~index () =
  let open CCResult.Infix in
  Terrat_change_match.synthesize_dir_config ~index ~file_list:repo_tree repo_config
  >>= fun dirs ->
  let all_matching_dirspaces =
    CCList.flat_map
      CCFun.(Terrat_change_match.of_dirspace dirs %> CCOption.to_list)
      out_of_change_applies
  in
  let all_matching_diff = Terrat_change_match.match_diff_list dirs diff in
  let all_matches = Terrat_change_match.merge_with_dedup all_matching_diff all_matching_dirspaces in
  let tag_query_matches =
    CCList.filter (Terrat_change_match.match_tag_query ~tag_query) all_matches
  in
  Ok (tag_query_matches, all_matches)

let match_tag_queries ~accessor ~changes queries =
  CCList.map
    (fun change ->
      ( change,
        CCList.find_idx
          (fun q -> Terrat_change_match.match_tag_query ~tag_query:(accessor q) change)
          queries ))
    changes

let dirspaceflows_of_changes repo_config changes =
  let module E = struct
    exception Err of Terrat_tag_query_ast.err
  end in
  let workflows = CCOption.get_or ~default:[] repo_config.Terrat_repo_config.Version_1.workflows in
  try
    Ok
      (CCList.map
         (fun (Terrat_change_match.{ dirspace; _ }, workflow) ->
           Terrat_change.Dirspaceflow.
             {
               dirspace;
               workflow = CCOption.map (fun (idx, workflow) -> Workflow.{ idx; workflow }) workflow;
             })
         (match_tag_queries
            ~accessor:(fun Terrat_repo_config.Workflow_entry.{ tag_query; _ } ->
              match Terrat_tag_query.of_string tag_query with
              | Ok query -> query
              | Error err -> raise (E.Err err))
            ~changes
            workflows))
  with E.Err (#Terrat_tag_query_ast.err as err) -> Error err

module type S = sig
  module Account : sig
    type t

    val to_string : t -> string
  end

  module Db : sig
    type err = Pgsql_io.err [@@deriving show]
    type t

    val request_id : t -> string

    val tx :
      t -> f:(unit -> ('a, ([> err ] as 'e)) result Abb.Future.t) -> ('a, 'e) result Abb.Future.t
  end

  module Client : sig
    type t

    val request_id : t -> string
  end

  module Ref : sig
    type t

    val to_string : t -> string
    val of_string : string -> t
  end

  module Repo : sig
    type t

    val to_string : t -> string
  end

  module Remote_repo : sig
    type t

    val default_branch : t -> Ref.t
  end

  module Index : sig
    type t

    val make : ?pull_number:int -> account:Account.t -> branch:Ref.t -> repo:Repo.t -> unit -> t
    val account : t -> Account.t
    val pull_number : t -> int option
    val repo : t -> Repo.t
  end

  module Drift : sig
    type t

    val make : account:Account.t -> branch:Ref.t -> reconcile:bool -> repo:Repo.t -> unit -> t
    val account : t -> Account.t
    val branch : t -> Ref.t
    val reconcile : t -> bool
    val repo : t -> Repo.t
  end

  module Pull_request : sig
    type stored
    type fetched
    type 'a t

    val account : 'a t -> Account.t
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
  end

  module Access_control : Terrat_access_control.S

  module Apply_requirements : sig
    type t

    val passed : t -> bool
    val approved_reviews : t -> Terrat_pull_request_review.t list
  end

  val create_client : Terrat_config.t -> Account.t -> (Client.t, [> `Error ]) result Abb.Future.t

  val fetch_pull_request :
    Account.t ->
    Client.t ->
    Repo.t ->
    int ->
    (Pull_request.fetched Pull_request.t, [> `Error ]) result Abb.Future.t

  val store_pull_request :
    Db.t -> Pull_request.fetched Pull_request.t -> (unit, [> `Error ]) result Abb.Future.t

  val fetch_remote_repo : Client.t -> Repo.t -> (Remote_repo.t, [> `Error ]) result Abb.Future.t

  val fetch_repo_config :
    Client.t -> Repo.t -> Ref.t -> (Terrat_repo_config.Version_1.t, [> `Error ]) result Abb.Future.t

  val fetch_tree : Client.t -> Repo.t -> Ref.t -> (string list, [> `Error ]) result Abb.Future.t

  val query_index :
    Db.t ->
    Account.t ->
    Ref.t ->
    (Terrat_change_match.Index.t option, [> `Error ]) result Abb.Future.t

  val query_account_status :
    Db.t -> Account.t -> ([ `Active | `Expired | `Disabled ], [> `Error ]) result Abb.Future.t

  val query_pull_request_out_of_change_applies :
    Db.t -> 'a Pull_request.t -> (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_dirspaces_without_valid_plans :
    Db.t ->
    'a Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_conflicting_work_manifests_in_repo :
    Db.t ->
    'a Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    Tf_operation.t ->
    ( (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
      Terrat_work_manifest2.Existing.t
      list,
      [> `Error ] )
    result
    Abb.Future.t

  val query_unapplied_dirspaces :
    Db.t -> 'a Pull_request.t -> (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_dirspaces_owned_by_other_pull_requests :
    Db.t ->
    'a Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    ((Terrat_change.Dirspace.t * Pull_request.stored Pull_request.t) list, [> `Error ]) result
    Abb.Future.t

  val create_work_manifest :
    Db.t ->
    ('a Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t Terrat_work_manifest2.New.t ->
    ( (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
      Terrat_work_manifest2.Existing.t,
      [> `Error ] )
    result
    Abb.Future.t

  val update_work_manifest :
    Db.t ->
    (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
    Terrat_work_manifest2.Existing.t ->
    ( (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
      Terrat_work_manifest2.Existing.t,
      [> `Error ] )
    result
    Abb.Future.t

  val update_work_manifest_state :
    Db.t ->
    (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
    Terrat_work_manifest2.Existing.t ->
    ( (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
      Terrat_work_manifest2.Existing.t,
      [> `Error ] )
    result
    Abb.Future.t

  val update_work_manifest_run_id :
    Db.t ->
    (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
    Terrat_work_manifest2.Existing.t ->
    ( (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
      Terrat_work_manifest2.Existing.t,
      [> `Error ] )
    result
    Abb.Future.t

  val query_work_manifest :
    Db.t ->
    Uuidm.t ->
    ( (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
      Terrat_work_manifest2.Existing.t
      option,
      [> `Error ] )
    result
    Abb.Future.t

  val store_dirspaceflows :
    base_ref:Ref.t ->
    branch_ref:Ref.t ->
    Db.t ->
    Repo.t ->
    Terrat_change.Dirspaceflow.Workflow.t Terrat_change.Dirspaceflow.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  (* User notification *)
  val make_commit_check :
    ?run_id:string ->
    description:string ->
    title:string ->
    status:Terrat_commit_check.Status.t ->
    Repo.t ->
    Terrat_commit_check.t

  val create_commit_checks :
    Client.t ->
    Repo.t ->
    Ref.t ->
    Terrat_commit_check.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val fetch_commit_checks :
    Client.t -> Repo.t -> Ref.t -> (Terrat_commit_check.t list, [> `Error ]) result Abb.Future.t

  val merge_pull_request : Client.t -> 'a Pull_request.t -> (unit, [> `Error ]) result Abb.Future.t

  val delete_pull_request_branch :
    Client.t -> 'a Pull_request.t -> (unit, [> `Error ]) result Abb.Future.t

  module Publish_msg : sig
    type t

    val publish_msg :
      t ->
      ( 'a Pull_request.t,
        ('a Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t,
        Apply_requirements.t )
      Msg.t ->
      (unit, [> `Error ]) result Abb.Future.t

    val make : client:Client.t -> pull_number:int -> repo:Repo.t -> user:string -> unit -> t
  end

  module Event : sig
    module Terraform : sig
      type t
      type r

      val account : t -> Account.t
      val config : t -> Terrat_config.t
      val create_access_control_ctx : t -> Client.t -> Access_control.ctx
      val pull_number : t -> int
      val repo : t -> Repo.t
      val request_id : t -> string
      val tag_query : t -> Terrat_tag_query.t
      val tf_operation : t -> Tf_operation.t
      val user : t -> string

      (* Publish messages back *)
      val publish_msg : t -> Client.t -> Publish_msg.t

      (* Return operations *)
      val noop : t -> r

      val created_work_manifest :
        t ->
        (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
        Terrat_work_manifest2.Existing.t ->
        r

      val with_db :
        t ->
        f:(Db.t -> ('a, ([> Pgsql_pool.err ] as 'e)) result Abb.Future.t) ->
        ('a, 'e) result Abb.Future.t

      val check_apply_requirements :
        t ->
        Client.t ->
        Pull_request.fetched Pull_request.t ->
        Terrat_repo_config.Version_1.t ->
        (Apply_requirements.t, [> `Error ]) result Abb.Future.t
    end

    module Initiate : sig
      type t
      type r

      (* Responses *)
      val of_work_manifest :
        t ->
        (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
        Terrat_work_manifest2.Existing.t ->
        (r, [> `Error | `Bad_glob_err of string * string ]) result Abb.Future.t

      val done_ :
        t ->
        (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
        Terrat_work_manifest2.Existing.t ->
        r Abb.Future.t

      val work_manifest_not_found : t -> r

      val with_db :
        t ->
        f:(Db.t -> ('a, ([> Pgsql_pool.err ] as 'e)) result Abb.Future.t) ->
        ('a, 'e) result Abb.Future.t

      val terraform_event :
        t -> 'a Pull_request.t -> 'b Terrat_work_manifest2.Existing.t -> Terraform.t

      val work_manifest_of_terraform_r :
        Terraform.r ->
        (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
        Terrat_work_manifest2.Existing.t
        option

      val branch_ref : t -> Ref.t
      val config : t -> Terrat_config.t
      val request_id : t -> string
      val run_id : t -> string
      val work_manifest_id : t -> Uuidm.t
    end

    module Plan : sig
      type t
    end

    module Plan_cleanup : sig
      type t
      type r

      val request_id : t -> string
      val delete_expired_plans : t -> (unit, [> `Error ]) result Abb.Future.t
      val done_ : t -> r
    end

    module Plan_get : sig
      type t
      type r

      val dir : t -> string
      val query_plan : t -> (Plan.t option, [> `Error ]) result Abb.Future.t
      val request_id : t -> string
      val work_manifest_id : t -> Uuidm.t
      val workspace : t -> string

      (* Returns *)
      val of_plan : t -> Plan.t -> r
      val plan_not_found : t -> r
    end

    module Plan_set : sig
      type t
      type r

      val dir : t -> string
      val request_id : t -> string
      val work_manifest_id : t -> Uuidm.t
      val workspace : t -> string
      val store_plan : t -> (unit, [> `Error ]) result Abb.Future.t

      (* Return *)
      val done_ : t -> r
    end

    module Result : sig
      module Type : sig
        type tf_operation
        type index
      end

      type t
      type r

      val with_db :
        t ->
        f:(Db.t -> ('a, ([> Pgsql_pool.err ] as 'e)) result Abb.Future.t) ->
        ('a, 'e) result Abb.Future.t

      val config : t -> Terrat_config.t
      val request_id : t -> string
      val work_manifest_id : t -> Uuidm.t
      val result_type : t -> [ `Tf_operation of Type.tf_operation | `Index of Type.index ]
      val store_result : Db.t -> t -> (unit, [> `Error ]) result Abb.Future.t
      val result_status : Type.tf_operation -> Result_status.t
      val index_results : Type.index -> bool * (string * int option * string) list

      val publish_result :
        t ->
        Type.tf_operation ->
        Pull_request.stored Pull_request.t ->
        'a Terrat_work_manifest2.Existing.t ->
        (unit, [> `Error ]) result Abb.Future.t

      (* Results *)
      val noop : t -> r

      val invalid_work_manifest_state :
        t ->
        (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
        Terrat_work_manifest2.Existing.t ->
        r

      val work_manifest_not_found : t -> r
    end

    module Repo_config : sig
      type t
      type r

      val account : t -> Account.t
      val config : t -> Terrat_config.t
      val pull_number : t -> int
      val repo : t -> Repo.t
      val request_id : t -> string
      val user : t -> string

      val with_db :
        t ->
        f:(Db.t -> ('a, ([> Pgsql_pool.err ] as 'e)) result Abb.Future.t) ->
        ('a, 'e) result Abb.Future.t

      (* Response *)
      val noop : t -> r
    end

    module Unlock : sig
      type t
      type r

      (* Returns *)
      val noop : t -> r

      (* Accessors *)
      val account : t -> Account.t
      val client : t -> Client.t
      val create_access_control_ctx : t -> Client.t -> Access_control.ctx
      val ids : t -> Unlock_id.t list
      val publish_msg : t -> Publish_msg.t
      val repo : t -> Repo.t
      val request_id : t -> string
      val unlock : t -> Unlock_id.t -> (unit, [> `Error ]) result Abb.Future.t
      val user : t -> string
    end

    module Drift : sig
      module Schedule : sig
        type t

        val account : t -> Account.t
        val reconcile : t -> bool
        val repo : t -> Repo.t
        val request_id : t -> string
      end

      module Data : sig
        type t

        val branch_name : t -> Ref.t
        val branch_ref : t -> Ref.t
        val index : t -> Terrat_change_match.Index.t option
        val repo_config : t -> Terrat_repo_config.Version_1.t
        val tree : t -> string list
      end

      type t
      type r

      val noop : t -> r

      val with_db :
        t ->
        f:(Db.t -> ('a, ([> Pgsql_pool.err ] as 'e)) result Abb.Future.t) ->
        ('a, 'e) result Abb.Future.t

      val query_missing_scheduled_runs : t -> (Schedule.t list, [> `Error ]) result Abb.Future.t
      val fetch_data : t -> Schedule.t -> (Data.t, [> `Error ]) result Abb.Future.t
    end

    module Index : sig
      type t
      type r

      val account : t -> Account.t
      val config : t -> Terrat_config.t
      val pull_number : t -> int
      val repo : t -> Repo.t
      val request_id : t -> string
      val user : t -> string

      val with_db :
        t ->
        f:(Db.t -> ('a, ([> Pgsql_pool.err ] as 'e)) result Abb.Future.t) ->
        ('a, 'e) result Abb.Future.t

      (* Return *)
      val noop : t -> r
    end

    module Push : sig
      type t
      type r

      val noop : t -> r
      val update_drift_schedule : t -> (unit, [> `Error ]) result Abb.Future.t
      val drift_of_t : t -> Drift.t
      val repo : t -> Repo.t
      val request_id : t -> string
      val branch : t -> Ref.t
    end
  end

  module Runner : sig
    type t
    type r

    val request_id : t -> string
    val completed : t -> r

    val client :
      t ->
      (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
      Terrat_work_manifest2.Existing.t ->
      (Client.t, [> `Error ]) result Abb.Future.t

    val next_work_manifest :
      t ->
      ( (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
        Terrat_work_manifest2.Existing.t
        option,
        [> `Error ] )
      result
      Abb.Future.t

    val run_work_manifest :
      t ->
      Client.t ->
      (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
      Terrat_work_manifest2.Existing.t ->
      (unit, [> `Error ]) result Abb.Future.t
  end
end

module Make (S : S) = struct
  let log_work_manifest
      request_id
      { Terrat_work_manifest2.id; state; base_hash; hash; run_id; run_type; src; _ } =
    let module Wm = Terrat_work_manifest2 in
    Logs.info (fun m ->
        m
          "EVALUATOR : %s : WORK_MANIFEST : id=%a : state=%s : run_type=%s : base_ref=%s : \
           branch_ref=%s : run_id=%s : run_kind=%s"
          request_id
          Uuidm.pp
          id
          (Wm.State.to_string state)
          (Wm.Run_type.to_string run_type)
          base_hash
          hash
          (CCOption.get_or ~default:"" run_id)
          (match src with
          | Wm.Kind.Pull_request _ -> "pr"
          | Wm.Kind.Drift _ -> "drift"
          | Wm.Kind.Index _ -> "index"))

  let log_time ?m request_id name t =
    Logs.info (fun m -> m "EVALUATOR : %s : %s : time=%f" request_id name t);
    match m with
    | Some m -> Metrics.DefaultHistogram.observe m t
    | None -> ()

  let create_client request_id config account =
    Abbs_time_it.run (log_time request_id "CREATE_CLIENT") (fun () ->
        S.create_client config account)

  module Access_control = Terrat_access_control.Make (S.Access_control)

  module Access_control_engine = struct
    module V1 = Terrat_repo_config.Version_1
    module Ac = Terrat_repo_config.Access_control
    module P = Terrat_repo_config.Access_control_policy

    let default_terrateam_config_update = [ "*" ]
    let default_plan = [ "*" ]
    let default_apply = [ "*" ]
    let default_apply_force = []
    let default_apply_autoapprove = []
    let default_unlock = [ "*" ]
    let default_apply_with_superapproval = []
    let default_superapproval = []

    type t = {
      config : Terrat_repo_config.Access_control.t;
      ctx : S.Access_control.ctx;
      policy_branch : S.Ref.t;
      request_id : string;
      user : string;
    }

    let make ~request_id ~ctx ~repo_config ~user ~policy_branch () =
      let default = Terrat_repo_config.Access_control.make () in
      let config = CCOption.get_or ~default repo_config.V1.access_control in
      { config; ctx; policy_branch; request_id; user }

    let policy_branch t = S.Ref.to_string t.policy_branch

    let eval_repo_config t diff =
      let terrateam_config_update =
        CCOption.get_or ~default:default_terrateam_config_update t.config.Ac.terrateam_config_update
      in
      if t.config.Ac.enabled then
        Abbs_time_it.run (log_time t.request_id "ACCESS_CONTROL_EVAL_REPO_CONFIG") (fun () ->
            let open Abbs_future_combinators.Infix_result_monad in
            Access_control.eval_repo_config t.ctx terrateam_config_update diff
            >>| function
            | true -> None
            | false -> Some terrateam_config_update)
      else (
        Logs.debug (fun m -> m "EVALUATOR : %s : ACCESS_CONTROL_DISABLED" t.request_id);
        Abb.Future.return (Ok None))

    let eval' t change_matches default selector =
      let module Err = struct
        exception Err of Terrat_tag_query_ast.err
      end in
      try
        if t.config.Ac.enabled then
          let policies =
            match t.config.Ac.policies with
            | None ->
                (* If no policy is specified, then use the default *)
                [
                  Terrat_access_control.Policy.
                    { tag_query = Terrat_tag_query.any; policy = default };
                ]
            | Some policies ->
                (* Policies have been specified, but that doesn't mean the specific
                   operation that is being executed has a configuration.  So iterate
                   through and pluck out the specific configuration and take the
                   default if that configuration was not specified. *)
                policies
                |> CCList.map
                     (fun (Terrat_repo_config.Access_control_policy.{ tag_query; _ } as p) ->
                       match Terrat_tag_query.of_string tag_query with
                       | Ok tag_query ->
                           Terrat_access_control.Policy.
                             { tag_query; policy = CCOption.get_or ~default (selector p) }
                       | Error err -> raise (Err.Err err))
          in
          Abbs_time_it.run (log_time t.request_id "ACCESS_CONTROL_SUPERAPPROVAL_EVAL") (fun () ->
              Access_control.eval t.ctx policies change_matches)
        else (
          Logs.debug (fun m -> m "EVALUATOR : %s : ACCESS_CONTROL_DISABLED" t.request_id);
          Abb.Future.return (Ok Terrat_access_control.R.{ pass = change_matches; deny = [] }))
      with Err.Err (#Terrat_tag_query_ast.err as err) -> Abb.Future.return (Error err)

    let eval_superapproved t reviewers change_matches =
      let open Abbs_future_combinators.Infix_result_monad in
      (* First, let's see if this user can even apply any of the denied changes
         if there is a superapproval. If there isn't, we return the original
         response, otherwise we have to see if any of the changes have super
         approvals. *)
      eval'
        t
        change_matches
        default_apply_with_superapproval
        (fun P.{ apply_with_superapproval; _ } -> apply_with_superapproval)
      >>= function
      | Terrat_access_control.R.{ pass = _ :: _ as pass; deny } ->
          (* Now, of those that passed, let's see if any have been approved by a
             super approver.  To do this we'll iterate over the approvers. *)
          let pass_with_superapproval =
            pass
            |> CCList.map (fun (Terrat_change_match.{ dirspace; _ } as ch) -> (dirspace, ch))
            |> Dirspace_map.of_list
          in
          Abbs_future_combinators.List_result.fold_left
            ~f:(fun acc user ->
              let changes = acc |> Dirspace_map.to_list |> CCList.map snd in
              let ctx = S.Access_control.set_user user t.ctx in
              let t' = { t with ctx } in
              eval' t' changes default_superapproval (fun P.{ superapproval; _ } -> superapproval)
              >>= fun Terrat_access_control.R.{ pass; _ } ->
              let acc =
                CCListLabels.fold_left
                  ~f:(fun acc Terrat_change_match.{ dirspace; _ } ->
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
      | `Plan -> eval' t change_matches default_plan (fun P.{ plan; _ } -> plan)
      | `Apply reviewers -> (
          let open Abbs_future_combinators.Infix_result_monad in
          eval' t change_matches default_apply (fun P.{ apply; _ } -> apply)
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
                         { change_match = Terrat_change_match.{ dirspace; _ }; _ } ->
                    not (Dirspace_map.mem dirspace superapproved))
                  deny
              in
              Abb.Future.return (Ok Terrat_access_control.R.{ pass; deny })
          | r -> Abb.Future.return (Ok r))
      | `Apply_force ->
          eval' t change_matches default_apply_force (fun P.{ apply_force; _ } -> apply_force)
      | `Apply_autoapprove ->
          eval' t change_matches default_apply_autoapprove (fun P.{ apply_autoapprove; _ } ->
              apply_autoapprove)

    let eval_pr_operation t = function
      | `Unlock ->
          if t.config.Ac.enabled then
            let match_list = CCOption.get_or ~default:default_unlock t.config.Ac.unlock in
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

  let fetch_pull_request account client repo pull_number =
    Abbs_time_it.run
      (log_time (S.Client.request_id client) "FETCH_PULL_REQUEST")
      (fun () -> S.fetch_pull_request account client repo pull_number)

  let store_pull_request db pull_request =
    Abbs_time_it.run
      (log_time (S.Db.request_id db) "STORE_PULL_REQUEST")
      (fun () -> S.store_pull_request db pull_request)

  let fetch_repo_config client repo ref_ =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FETCH_REPO_CONFIG : repo=%s : ref=%s : time=%f"
              (S.Client.request_id client)
              (S.Repo.to_string repo)
              (S.Ref.to_string ref_)
              time))
      (fun () -> S.fetch_repo_config client repo ref_)

  let fetch_remote_repo client repo =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FETCH_REMOTE_REPO : repo=%s : time=%f"
              (S.Client.request_id client)
              (S.Repo.to_string repo)
              time))
      (fun () -> S.fetch_remote_repo client repo)

  let fetch_tree client repo ref_ =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : FETCH_TREE : repo=%s : ref=%s : time=%f"
              (S.Client.request_id client)
              (S.Repo.to_string repo)
              (S.Ref.to_string ref_)
              time))
      (fun () -> S.fetch_tree client repo ref_)

  let query_index db account ref_ =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : QUERY_INDEX : ref=%s : time=%f"
              (S.Db.request_id db)
              (S.Ref.to_string ref_)
              time))
      (fun () -> S.query_index db account ref_)

  let query_unapplied_dirspaces db pull_request =
    Abbs_time_it.run
      (log_time (S.Db.request_id db) "QUERY_UNAPPLIED_DIRSPACES")
      (fun () -> S.query_unapplied_dirspaces db pull_request)

  let create_commit_checks client repo ref_ checks =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : CREATE_COMMIT_CHECKS : repo=%s : num=%d : time=%f"
              (S.Client.request_id client)
              (S.Repo.to_string repo)
              (CCList.length checks)
              time))
      (fun () -> S.create_commit_checks client repo ref_ checks)

  let fetch_commit_checks client repo ref_ =
    Abbs_time_it.run
      (log_time (S.Client.request_id client) "FETCH_COMMIT_CHECKS")
      (fun () -> S.fetch_commit_checks client repo ref_)

  let store_dirspaceflows ~base_ref ~branch_ref db repo dirspaceflows =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : STORE_DIRSPACEFLOWS : repo=%s : num=%d : time=%f"
              (S.Db.request_id db)
              (S.Repo.to_string repo)
              (CCList.length dirspaceflows)
              time))
      (fun () -> S.store_dirspaceflows ~base_ref ~branch_ref db repo dirspaceflows)

  let create_work_manifest db work_manifest =
    Abbs_time_it.run
      (log_time (S.Db.request_id db) "CREATE_WORK_MANIFEST")
      (fun () -> S.create_work_manifest db work_manifest)

  let update_work_manifest db work_manifest =
    Abbs_time_it.run
      (log_time (S.Db.request_id db) "UPDATE_WORK_MANIFEST")
      (fun () -> S.update_work_manifest db work_manifest)

  let update_work_manifest_state db work_manifest =
    Abbs_time_it.run
      (log_time (S.Db.request_id db) "UPDATE_WORK_MANIFEST_STATE")
      (fun () -> S.update_work_manifest_state db work_manifest)

  let update_work_manifest_run_id db work_manifest =
    Abbs_time_it.run
      (log_time (S.Db.request_id db) "UPDATE_WORK_MANIFEST_RUN_ID")
      (fun () -> S.update_work_manifest_run_id db work_manifest)

  let query_work_manifest db work_manifest_id =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : QUERY_WORK_MANIFEST : id=%a : time=%f"
              (S.Db.request_id db)
              Uuidm.pp
              work_manifest_id
              time))
      (fun () -> S.query_work_manifest db work_manifest_id)

  let query_dirspaces_without_valid_plans db pull_request dirspaces =
    Abbs_time_it.run
      (log_time (S.Db.request_id db) "QUERY_DIRSPACES_WITHOUT_VALID_PLANS")
      (fun () -> S.query_dirspaces_without_valid_plans db pull_request dirspaces)

  let query_dirspaces_owned_by_other_pull_requests db pull_request dirspaces =
    Abbs_time_it.run
      (log_time (S.Db.request_id db) "QUERY_DIRSPACES_OWNED_BY_OTHER_PULL_REQUESTS")
      (fun () -> S.query_dirspaces_owned_by_other_pull_requests db pull_request dirspaces)

  let merge_pull_request client pull_request =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : MERGE_PULL_REQUEST : repo=%s : time=%f"
              (S.Client.request_id client)
              (S.Repo.to_string (S.Pull_request.repo pull_request))
              time))
      (fun () -> S.merge_pull_request client pull_request)

  let delete_pull_request_branch client pull_request =
    Abbs_time_it.run
      (fun time ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : MERGE_PULL_REQUEST : repo=%s : time=%f"
              (S.Client.request_id client)
              (S.Repo.to_string (S.Pull_request.repo pull_request))
              time))
      (fun () -> S.delete_pull_request_branch client pull_request)

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

  (* Get a destination branch from the destination branch configuration and
     normalize it all on the Destination_branch_object type so it's easier to
     work with. *)
  let get_destination_branch =
    let module D = Terrat_repo_config.Version_1.Destination_branches.Items in
    let module O = Terrat_repo_config.Destination_branch_object in
    function
    | D.Destination_branch_name branch -> O.make ~branch ()
    | D.Destination_branch_object obj -> obj

  let rec eval_destination_branch_match dest_branch source_branch =
    let module Obj = Terrat_repo_config.Destination_branch_object in
    function
    | [] -> Error `No_matching_dest_branch
    | Obj.{ branch; source_branches } :: valid_branches -> (
        let branch_glob = pattern_of_glob (CCString.lowercase_ascii branch) in
        match Lua_pattern.find dest_branch branch_glob with
        | Some _ ->
            (* Partition the source branches into the not patterns and the
               positive patterns. *)
            let not_branches, branches =
              CCList.partition
                (CCString.prefix ~pre:"!")
                (CCOption.get_or ~default:[ "*" ] source_branches)
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

  (* Given a pull request and a repo configuration, validate that the
     destination branch and the source branch are valid.  Everything is
     converted to lowercase. *)
  let is_valid_destination_branch repo_config default_branch base_branch_name branch_name =
    let module Rc = Terrat_repo_config_version_1 in
    let module Obj = Terrat_repo_config.Destination_branch_object in
    let valid_branches =
      CCOption.map_or
        ~default:[ Obj.make ~branch:(S.Ref.to_string default_branch) () ]
        (CCList.map get_destination_branch)
        repo_config.Rc.destination_branches
    in
    let dest_branch = CCString.lowercase_ascii (S.Ref.to_string base_branch_name) in
    let source_branch = CCString.lowercase_ascii (S.Ref.to_string branch_name) in
    eval_destination_branch_match dest_branch source_branch valid_branches

  module Event = struct
    module Drift = struct
      let fetch_data t sched =
        let repo = S.Event.Drift.Schedule.repo sched in
        Abbs_time_it.run
          (fun time ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : FETCH_DATA : repo=%s : time=%f"
                  (S.Event.Drift.Schedule.request_id sched)
                  (S.Repo.to_string repo)
                  time))
          (fun () -> S.Event.Drift.fetch_data t sched)

      let create_scheduled_work_manifest db sched data dirspaceflows =
        let open Abbs_future_combinators.Infix_result_monad in
        let module Wm = Terrat_work_manifest2 in
        let branch = S.Event.Drift.Data.branch_name data in
        let account = S.Event.Drift.Schedule.account sched in
        let repo = S.Event.Drift.Schedule.repo sched in
        let reconcile = S.Event.Drift.Schedule.reconcile sched in
        let branch_ref = S.Ref.to_string (S.Event.Drift.Data.branch_ref data) in
        let changes =
          let module Dsf = Terrat_change.Dirspaceflow in
          CCList.map
            (fun ({ Dsf.workflow; _ } as dsf) ->
              { dsf with Dsf.workflow = CCOption.map (fun Dsf.Workflow.{ idx; _ } -> idx) workflow })
            dirspaceflows
        in
        let work_manifest =
          {
            Wm.base_hash = branch_ref;
            changes;
            completed_at = None;
            created_at = ();
            denied_dirspaces = [];
            hash = branch_ref;
            id = ();
            run_id = ();
            run_type = Wm.Run_type.Plan;
            src = Wm.Kind.Drift (S.Drift.make ~account ~branch ~reconcile ~repo ());
            state = ();
            tag_query = Terrat_tag_query.any;
            user = None;
          }
        in
        create_work_manifest db work_manifest
        >>= fun work_manifest ->
        update_work_manifest db work_manifest >>= fun _ -> Abb.Future.return (Ok ())

      let run_schedule' t sched =
        let open Abbs_future_combinators.Infix_result_monad in
        fetch_data t sched
        >>= fun data ->
        match S.Event.Drift.Data.index data with
        | Some index ->
            let diff =
              CCList.map
                (fun filename -> Terrat_change.Diff.Change { filename })
                (S.Event.Drift.Data.tree data)
            in
            Abb.Future.return
              (compute_matches
                 ~repo_config:(S.Event.Drift.Data.repo_config data)
                 ~tag_query:Terrat_tag_query.any
                 ~out_of_change_applies:[]
                 ~diff
                 ~repo_tree:(S.Event.Drift.Data.tree data)
                 ~index
                 ())
            >>= fun (tag_query_matches, _) ->
            Abb.Future.return
              (dirspaceflows_of_changes (S.Event.Drift.Data.repo_config data) tag_query_matches)
            >>= fun dirspaceflows ->
            S.Event.Drift.with_db t ~f:(fun db ->
                create_scheduled_work_manifest db sched data dirspaceflows)
        | None ->
            S.Event.Drift.with_db t ~f:(fun db -> create_scheduled_work_manifest db sched data [])

      let run_schedule t sched =
        let open Abb.Future.Infix_monad in
        run_schedule' t sched
        >>= function
        | Ok () -> Abb.Future.return (Ok ())
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m
                  "EVALUATOR : %s : DB : %a"
                  (S.Event.Drift.Schedule.request_id sched)
                  Pgsql_io.pp_err
                  err);
            Abb.Future.return (Error `Error)
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m
                  "EVALUATOR : %s : DB : %a"
                  (S.Event.Drift.Schedule.request_id sched)
                  Pgsql_pool.pp_err
                  err);
            Abb.Future.return (Error `Error)
        | Error (#Terrat_tag_query_ast.err as err) ->
            Logs.err (fun m ->
                m "EVALUATOR : DRIFT : TAG_QUERY_ERR : %a" Terrat_tag_query_ast.pp_err err);
            Abb.Future.return (Error `Error)
        | Error (`Bad_glob err) ->
            Logs.info (fun m -> m "EVALUATOR : DRIFT : BAD_GLOB : %s" err);
            Abb.Future.return (Error `Error)
        | Error `Error -> Abb.Future.return (Error `Error)

      let eval' t =
        let open Abbs_future_combinators.Infix_result_monad in
        S.Event.Drift.query_missing_scheduled_runs t
        >>= fun schedules ->
        Abbs_future_combinators.to_result
          (Abbs_future_combinators.List.iter
             ~f:(fun sched -> Abbs_future_combinators.ignore (run_schedule t sched))
             schedules)

      let eval t =
        let open Abb.Future.Infix_monad in
        eval' t
        >>= function
        | Ok _ -> Abb.Future.return (Ok (S.Event.Drift.noop t))
        | Error `Error -> Abb.Future.return (Error `Error)
    end

    module Index = struct
      let eval' t =
        let open Abbs_future_combinators.Infix_result_monad in
        let account = S.Event.Index.account t in
        let repo = S.Event.Index.repo t in
        let pull_number = S.Event.Index.pull_number t in
        create_client (S.Event.Index.request_id t) (S.Event.Index.config t) account
        >>= fun client ->
        fetch_pull_request account client repo pull_number
        >>= fun pull_request ->
        S.Event.Index.with_db t ~f:(fun db -> store_pull_request db pull_request)
        >>= fun () ->
        Abbs_future_combinators.Infix_result_app.(
          (fun repo_config repo_tree -> (repo_config, repo_tree))
          <$> fetch_repo_config client repo (S.Pull_request.branch_ref pull_request)
          <*> fetch_tree client repo (S.Pull_request.branch_ref pull_request))
        >>= fun (repo_config, repo_tree) ->
        Abb.Future.return
          (Terrat_change_match.synthesize_dir_config
             ~index:Terrat_change_match.Index.empty
             ~file_list:repo_tree
             repo_config)
        >>= fun dirs ->
        let matches =
          Terrat_change_match.match_diff_list
            dirs
            (CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) repo_tree)
        in
        Abb.Future.return (dirspaceflows_of_changes repo_config matches)
        >>= fun dirspaceflows ->
        let module Wm = Terrat_work_manifest2 in
        let changes =
          let module Dsf = Terrat_change.Dirspaceflow in
          CCList.map
            (fun ({ Dsf.workflow; _ } as dsf) ->
              { dsf with Dsf.workflow = CCOption.map (fun Dsf.Workflow.{ idx; _ } -> idx) workflow })
            dirspaceflows
        in
        let work_manifest =
          {
            Wm.base_hash = S.Ref.to_string (S.Pull_request.base_ref pull_request);
            changes;
            completed_at = None;
            created_at = ();
            denied_dirspaces = [];
            hash = S.Ref.to_string (S.Pull_request.branch_ref pull_request);
            id = ();
            src =
              Wm.Kind.Index
                (S.Index.make
                   ~pull_number:(S.Pull_request.id pull_request)
                   ~account
                   ~branch:(S.Pull_request.branch_name pull_request)
                   ~repo
                   ());
            run_id = ();
            run_type = Wm.Run_type.Plan;
            state = ();
            tag_query = Terrat_tag_query.any;
            user = Some (S.Event.Index.user t);
          }
        in
        S.Event.Index.with_db t ~f:(fun db ->
            create_work_manifest db work_manifest
            >>= fun work_manifest -> update_work_manifest db work_manifest)
        >>= fun _ -> Abb.Future.return (Ok (S.Event.Index.noop t))

      let eval t =
        let open Abb.Future.Infix_monad in
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : EVAL : INDEX : account=%s : repo=%s : pull_number=%d : user=%s"
              (S.Event.Index.request_id t)
              (S.Account.to_string (S.Event.Index.account t))
              (S.Repo.to_string (S.Event.Index.repo t))
              (S.Event.Index.pull_number t)
              (S.Event.Index.user t));
        eval' t
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error _ -> failwith "nyi"
    end

    module Plan_cleanup = struct
      let delete_expired_plans t =
        Abbs_time_it.run
          (fun time ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : DELETE_EXPIRED_PLANS : time=%f"
                  (S.Event.Plan_cleanup.request_id t)
                  time))
          (fun () -> S.Event.Plan_cleanup.delete_expired_plans t)

      let eval' t =
        let open Abbs_future_combinators.Infix_result_monad in
        delete_expired_plans t >>= fun () -> Abb.Future.return (Ok (S.Event.Plan_cleanup.done_ t))

      let eval t =
        let open Abb.Future.Infix_monad in
        eval' t
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error `Error -> Abb.Future.return (Error `Error)
    end

    module Plan_get = struct
      let query_plan t =
        Abbs_time_it.run
          (fun time ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : QUERY_PLAN : id=%a : dir=%s : workspace=%s : time=%f"
                  (S.Event.Plan_get.request_id t)
                  Uuidm.pp
                  (S.Event.Plan_get.work_manifest_id t)
                  (S.Event.Plan_get.dir t)
                  (S.Event.Plan_get.workspace t)
                  time))
          (fun () -> S.Event.Plan_get.query_plan t)

      let eval' t =
        let open Abbs_future_combinators.Infix_result_monad in
        query_plan t
        >>= function
        | Some plan -> Abb.Future.return (Ok (S.Event.Plan_get.of_plan t plan))
        | None -> Abb.Future.return (Ok (S.Event.Plan_get.plan_not_found t))

      let eval t =
        let open Abb.Future.Infix_monad in
        eval' t
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error `Error -> Abb.Future.return (Error `Error)
    end

    module Plan_set = struct
      let store_plan t =
        Abbs_time_it.run
          (fun time ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : STORE_PLAN : id=%a : dir=%s : workspace=%s : time=%f"
                  (S.Event.Plan_set.request_id t)
                  Uuidm.pp
                  (S.Event.Plan_set.work_manifest_id t)
                  (S.Event.Plan_set.dir t)
                  (S.Event.Plan_set.workspace t)
                  time))
          (fun () -> S.Event.Plan_set.store_plan t)

      let eval' t =
        let open Abbs_future_combinators.Infix_result_monad in
        store_plan t >>= fun () -> Abb.Future.return (Ok (S.Event.Plan_set.done_ t))

      let eval t =
        let open Abb.Future.Infix_monad in
        eval' t
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error `Error -> Abb.Future.return (Error `Error)
    end

    module Result = struct
      let publish_result t result pr wm =
        Abbs_time_it.run
          (fun time ->
            Logs.info (fun m ->
                m "EVALUATOR : %s : PUBLISH_RESULTS : time=%f" (S.Event.Result.request_id t) time))
          (fun () -> S.Event.Result.publish_result t result pr wm)

      let create_commit_checks
          t
          run_id
          pull_request
          run_type
          ref_
          { Result_status.dirspaces; overall; post_hooks; pre_hooks } =
        let open Abbs_future_combinators.Infix_result_monad in
        let module Status = Terrat_commit_check.Status in
        let repo = S.Pull_request.repo pull_request in
        let unified_run_type =
          let module Urt = Terrat_work_manifest2.Unified_run_type in
          run_type |> Urt.of_run_type |> Urt.to_string
        in
        let status = function
          | true -> Terrat_commit_check.Status.Completed
          | false -> Terrat_commit_check.Status.Failed
        in
        let description = function
          | true -> "Completed"
          | false -> "Failed"
        in
        let aggregate =
          [
            S.make_commit_check
              ?run_id
              ~description:(description pre_hooks)
              ~title:(Printf.sprintf "terrateam %s pre-hooks" unified_run_type)
              ~status:(status pre_hooks)
              repo;
            S.make_commit_check
              ?run_id
              ~description:(description post_hooks)
              ~title:(Printf.sprintf "terrateam %s post-hooks" unified_run_type)
              ~status:(status post_hooks)
              repo;
          ]
        in
        let dirspace_checks =
          let module Ds = Terrat_change.Dirspace in
          CCList.map
            (fun ({ Ds.dir; workspace }, success) ->
              S.make_commit_check
                ?run_id
                ~description:(description success)
                ~title:(Printf.sprintf "terrateam %s: %s %s" unified_run_type dir workspace)
                ~status:(status success)
                repo)
            dirspaces
        in
        let checks = aggregate @ dirspace_checks in
        create_client
          (S.Event.Result.request_id t)
          (S.Event.Result.config t)
          (S.Pull_request.account pull_request)
        >>= fun client -> create_commit_checks client repo (S.Ref.of_string ref_) checks

      let maybe_publish_result
          t
          pr
          result
          ({ Terrat_work_manifest2.run_id; run_type; hash; _ } as wm) =
        let result_status = S.Event.Result.result_status result in
        Abbs_future_combinators.Infix_result_app.(
          (fun _ _ -> ())
          <$> publish_result t result pr wm
          <*> create_commit_checks t run_id pr run_type hash result_status)

      let maybe_publish_index_result t result idx =
        let open Abbs_future_combinators.Infix_result_monad in
        match S.Index.pull_number idx with
        | Some pull_number ->
            create_client
              (S.Event.Result.request_id t)
              (S.Event.Result.config t)
              (S.Index.account idx)
            >>= fun client ->
            let publish_msg =
              S.Publish_msg.make ~client ~pull_number ~repo:(S.Index.repo idx) ~user:"" ()
            in
            S.Publish_msg.publish_msg
              publish_msg
              (Msg.Index_complete (S.Event.Result.index_results result))
        | None -> Abb.Future.return (Ok ())

      let automerge_config = function
        | Terrat_repo_config.(Version_1.{ automerge = Some _ as automerge; _ }) -> automerge
        | _ -> None

      let maybe_merge_and_delete t pr wm =
        let module Wm = Terrat_work_manifest2 in
        let open Abbs_future_combinators.Infix_result_monad in
        S.Event.Result.with_db t ~f:(fun db -> query_unapplied_dirspaces db pr)
        >>= function
        | [] -> (
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : ALL_DIRSPACES_APPLIED : %a"
                  (S.Event.Result.request_id t)
                  Uuidm.pp
                  wm.Wm.id);
            create_client
              (S.Event.Result.request_id t)
              (S.Event.Result.config t)
              (S.Pull_request.account pr)
            >>= fun client ->
            fetch_repo_config client (S.Pull_request.repo pr) (S.Ref.of_string wm.Wm.hash)
            >>= fun repo_config ->
            let module Am = Terrat_repo_config.Automerge in
            match automerge_config repo_config with
            | Some { Am.enabled = true; delete_branch } -> (
                let open Abb.Future.Infix_monad in
                merge_pull_request client pr
                >>= function
                | Ok () when delete_branch -> delete_pull_request_branch client pr
                | Ok () -> Abb.Future.return (Ok ())
                | Error _ -> failwith "nyi")
            | _ -> Abb.Future.return (Ok ()))
        | _ :: _ -> Abb.Future.return (Ok ())

      let maybe_reconcile_drift db t drift work_manifest =
        let module Wm = Terrat_work_manifest2 in
        let open Abbs_future_combinators.Infix_result_monad in
        if S.Drift.reconcile drift && work_manifest.Wm.run_type = Wm.Run_type.Plan then (
          let work_manifest =
            {
              work_manifest with
              Wm.id = ();
              completed_at = None;
              created_at = ();
              run_id = ();
              state = ();
              run_type = Wm.Run_type.Apply;
            }
          in
          create_work_manifest db work_manifest
          >>= fun work_manifest ->
          update_work_manifest db work_manifest
          >>= fun _ ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : CREATED_RECONCILE_WORK_MANIFEST : id=%a"
                (S.Event.Result.request_id t)
                Uuidm.pp
                work_manifest.Wm.id);
          Abb.Future.return (Ok ()))
        else Abb.Future.return (Ok ())

      let process_result db t wm =
        let module Wm = Terrat_work_manifest2 in
        let open Abbs_future_combinators.Infix_result_monad in
        S.Event.Result.store_result db t
        >>= fun () ->
        match (S.Event.Result.result_type t, wm.Wm.src) with
        | `Tf_operation result, Wm.Kind.Pull_request pr ->
            let wm = { wm with Wm.state = Wm.State.Completed } in
            log_work_manifest (S.Event.Result.request_id t) wm;
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : WORK_MANIFEST_RESULT : wm_run_kind=%s : result_kind=%s"
                  (S.Event.Result.request_id t)
                  "tf_op"
                  "tf_op");
            update_work_manifest_state db wm
            >>= fun wm ->
            maybe_publish_result t pr result wm
            >>= fun _ ->
            maybe_merge_and_delete t pr wm
            >>= fun () -> Abb.Future.return (Ok (S.Event.Result.noop t))
        | `Tf_operation result, Wm.Kind.Drift drift ->
            let wm = { wm with Wm.state = Wm.State.Completed } in
            log_work_manifest (S.Event.Result.request_id t) wm;
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : WORK_MANIFEST_RESULT : wm_run_kind=%s : result_kind=%s"
                  (S.Event.Result.request_id t)
                  "tf_op"
                  "tf_op");
            update_work_manifest_state db wm
            >>= fun wm ->
            maybe_reconcile_drift db t drift wm
            >>= fun () -> Abb.Future.return (Ok (S.Event.Result.noop t))
        | `Index result, Wm.Kind.Index idx ->
            let wm = { wm with Wm.state = Wm.State.Completed } in
            log_work_manifest (S.Event.Result.request_id t) wm;
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : WORK_MANIFEST_RESULT : wm_run_kind=%s : result_kind=%s : \
                   pull_number=%s"
                  (S.Event.Result.request_id t)
                  "index"
                  "index"
                  (CCOption.map_or ~default:"" CCInt.to_string (S.Index.pull_number idx)));
            update_work_manifest_state db wm
            >>= fun _ ->
            maybe_publish_index_result t result idx
            >>= fun () -> Abb.Future.return (Ok (S.Event.Result.noop t))
        | `Index _, (Wm.Kind.Pull_request _ | Wm.Kind.Drift _) ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : WORK_MANIFEST_RESULT : wm_run_kind=%s : result_kind=%s"
                  (S.Event.Result.request_id t)
                  "tf_op"
                  "index");
            Abb.Future.return (Ok (S.Event.Result.noop t))
        | `Tf_operation _, Wm.Kind.Index _ ->
            Logs.err (fun m ->
                m
                  "EVALUATOR : %s : WORK_MANIFEST_RESULT : wm_run_kind=%s : result_kind=%s"
                  (S.Event.Result.request_id t)
                  "index"
                  "tf_op");
            assert false

      let eval' t =
        let module Wm = Terrat_work_manifest2 in
        let open Abbs_future_combinators.Infix_result_monad in
        S.Event.Result.with_db t ~f:(fun db ->
            query_work_manifest db (S.Event.Result.work_manifest_id t)
            >>= function
            | Some ({ Wm.state = Wm.State.Running; _ } as wm) -> process_result db t wm
            | Some ({ Wm.state = Wm.State.(Aborted | Queued | Completed) as state; _ } as wm) ->
                Logs.info (fun m ->
                    m
                      "EVALUATOR : %s : WORK_MANIFEST_NOT_RUNNING : id=%a : state=%s"
                      (S.Event.Result.request_id t)
                      Uuidm.pp
                      (S.Event.Result.work_manifest_id t)
                      (Wm.State.to_string state));
                Abb.Future.return (Ok (S.Event.Result.invalid_work_manifest_state t wm))
            | None ->
                Logs.info (fun m ->
                    m
                      "EVALUATOR : %s : WORK_MANIFEST_NOT_FOUND : id=%a"
                      (S.Event.Result.request_id t)
                      Uuidm.pp
                      (S.Event.Result.work_manifest_id t));
                Abb.Future.return (Ok (S.Event.Result.work_manifest_not_found t)))

      let eval t =
        let open Abb.Future.Infix_monad in
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : EVAL : RESULT : id=%a"
              (S.Event.Result.request_id t)
              Uuidm.pp
              (S.Event.Result.work_manifest_id t));
        eval' t
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "EVALUATOR : %s : DB : %a" (S.Event.Result.request_id t) Pgsql_pool.pp_err err);
            Abb.Future.return (Error `Error)
        | Error `Error -> Abb.Future.return (Error `Error)
    end

    module Repo_config = struct
      let eval' t =
        let open Abbs_future_combinators.Infix_result_monad in
        let account = S.Event.Repo_config.account t in
        let repo = S.Event.Repo_config.repo t in
        create_client (S.Event.Repo_config.request_id t) (S.Event.Repo_config.config t) account
        >>= fun client ->
        fetch_pull_request account client repo (S.Event.Repo_config.pull_number t)
        >>= fun pull_request ->
        let branch_ref = S.Pull_request.branch_ref pull_request in
        Abbs_future_combinators.Infix_result_app.(
          (fun repo_config repo_tree index -> (repo_config, repo_tree, index))
          <$> fetch_repo_config client repo branch_ref
          <*> fetch_tree client repo branch_ref
          <*> S.Event.Repo_config.with_db t ~f:(fun db -> query_index db account branch_ref))
        >>= fun (repo_config, repo_tree, index) ->
        let index =
          let module V1 = Terrat_repo_config.Version_1 in
          match repo_config with
          | { V1.indexer = Some { V1.Indexer.enabled = true; _ }; _ } ->
              CCOption.get_or ~default:Terrat_change_match.Index.empty index
          | _ -> Terrat_change_match.Index.empty
        in
        let publish =
          S.Publish_msg.make
            ~client
            ~pull_number:(S.Pull_request.id pull_request)
            ~repo
            ~user:(S.Event.Repo_config.user t)
            ()
        in
        match Terrat_change_match.synthesize_dir_config ~index ~file_list:repo_tree repo_config with
        | Ok dirs ->
            S.Publish_msg.publish_msg publish (Msg.Repo_config (repo_config, dirs))
            >>= fun () -> Abb.Future.return (Ok (S.Event.Repo_config.noop t))
        | Error (`Bad_glob s) ->
            let open Abb.Future.Infix_monad in
            Logs.err (fun m ->
                m "EVALUATOR : %s : BAD_GLOB : %s" (S.Event.Repo_config.request_id t) s);
            Abbs_future_combinators.ignore (S.Publish_msg.publish_msg publish (Msg.Bad_glob s))
            >>= fun () -> Abb.Future.return (Error `Error)

      let eval t =
        let open Abb.Future.Infix_monad in
        eval' t
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m
                  "EVALUATOR : %s : DB : %a"
                  (S.Event.Repo_config.request_id t)
                  Pgsql_pool.pp_err
                  err);
            Abb.Future.return (Error `Error)
        | Error `Error -> Abb.Future.return (Error `Error)
    end

    module Terraform = struct
      type t = {
        client : S.Client.t;
        event : S.Event.Terraform.t;
        work_manifest :
          ( S.Pull_request.stored S.Pull_request.t,
            S.Drift.t,
            S.Index.t )
          Terrat_work_manifest2.Kind.t
          Terrat_work_manifest2.Existing.t
          option;
      }

      let publish_msg t msg =
        Abbs_time_it.run
          (log_time (S.Event.Terraform.request_id t.event) "PUBLISH_MSG")
          (fun () -> S.Publish_msg.publish_msg (S.Event.Terraform.publish_msg t.event t.client) msg)

      let fetch_change_data t client remote_repo pull_request =
        let open Abbs_future_combinators.Infix_result_monad in
        let default_repo_branch = S.Remote_repo.default_branch remote_repo in
        Abbs_future_combinators.Infix_result_app.(
          (fun repo_config repo_default_config repo_tree index ->
            (repo_config, repo_default_config, repo_tree, index))
          <$> fetch_repo_config
                client
                (S.Event.Terraform.repo t)
                (S.Pull_request.branch_ref pull_request)
          <*> fetch_repo_config client (S.Event.Terraform.repo t) default_repo_branch
          <*> fetch_tree client (S.Event.Terraform.repo t) (S.Pull_request.branch_ref pull_request)
          <*> S.Event.Terraform.with_db t ~f:(fun db ->
                  query_index
                    db
                    (S.Event.Terraform.account t)
                    (S.Pull_request.branch_ref pull_request)))
        >>= fun ((repo_config, repo_default_config, repo_tree, index) as ret) ->
        match
          is_valid_destination_branch
            repo_default_config
            default_repo_branch
            (S.Pull_request.base_branch_name pull_request)
            (S.Pull_request.branch_name pull_request)
        with
        | Ok () -> Abb.Future.return (Ok ret)
        | Error `No_matching_dest_branch ->
            Abb.Future.return (Error (`No_matching_dest_branch pull_request))
        | Error `No_matching_source_branch ->
            Abb.Future.return (Error (`No_matching_source_branch pull_request))

      let query_pull_request_out_of_change_applies db pull_request =
        Abbs_time_it.run
          (log_time (S.Db.request_id db) "QUERY_PULL_REQUEST_OUT_OF_CHANGE_APPLIES")
          (fun () -> S.query_pull_request_out_of_change_applies db pull_request)

      let query_conflicting_work_manifests_in_repo db pull_request dirspaces operation =
        Abbs_time_it.run
          (log_time (S.Db.request_id db) "QUERY_CONFLICTING_WORK_MANIFESTS")
          (fun () -> S.query_conflicting_work_manifests_in_repo db pull_request dirspaces operation)

      let check_apply_requirements t client pull_request repo_config =
        Abbs_time_it.run
          (log_time (S.Event.Terraform.request_id t) "CHECK_APPLY_REQUIREMENTS")
          (fun () -> S.Event.Terraform.check_apply_requirements t client pull_request repo_config)

      let test_can_perform_operation t db pull_request dirspaces operation =
        let open Abbs_future_combinators.Infix_result_monad in
        Abbs_time_it.run
          (log_time (S.Event.Terraform.request_id t) "QUERY_ACCOUNT_STATUS")
          (fun () -> S.query_account_status db (S.Event.Terraform.account t))
        >>= function
        | `Active -> (
            query_conflicting_work_manifests_in_repo db pull_request dirspaces operation
            >>= function
            | [] -> Abb.Future.return (Ok `Valid)
            | wms -> Abb.Future.return (Ok (`Conflicting_work_manifests wms)))
        | `Expired | `Disabled -> Abb.Future.return (Ok `Account_expired)

      (* Given a plan event and the list of matches, if the event is an auto,
         filter out any dirspaces that have already been run.  If manual, return
         the list as-is.  This is because some operations on pull request might
         cause an autoplan event but we only want to run those dirspaces that have
         not been run for that commit.  In github, the primary example of this is
         making a draft PR ready for review.  If a user has been planning along
         the way, we don't want to initiate a new plan when they switch to ready,
         instead we just want to plan any missing directories. *)
      let missing_autoplan_matches t db pull_request matches = function
        | Tf_operation.Auto ->
            let module Cm = Terrat_change_match in
            let open Abbs_future_combinators.Infix_result_monad in
            query_dirspaces_without_valid_plans
              db
              pull_request
              (CCList.map (fun Cm.{ dirspace; _ } -> dirspace) matches)
            >>= fun dirspaces ->
            let dirspaces = Dirspace_set.of_list dirspaces in
            Abb.Future.return
              (Ok
                 (CCList.filter
                    (fun Cm.{ dirspace; _ } -> Dirspace_set.mem dirspace dirspaces)
                    matches))
        | Tf_operation.Manual -> Abb.Future.return (Ok matches)

      let create_queued_commit_checks client repo ref_ work_manifest =
        let module Wm = Terrat_work_manifest2 in
        match work_manifest.Wm.changes with
        | [] ->
            (* No changes, don't create any commit checks *)
            Abb.Future.return (Ok ())
        | dirspaces ->
            let module Status = Terrat_commit_check.Status in
            let unified_run_type =
              let module Urt = Terrat_work_manifest2.Unified_run_type in
              work_manifest.Wm.run_type |> Urt.of_run_type |> Urt.to_string
            in
            let aggregate =
              [
                S.make_commit_check
                  ~description:"Queued"
                  ~title:(Printf.sprintf "terrateam %s pre-hooks" unified_run_type)
                  ~status:Status.Queued
                  repo;
                S.make_commit_check
                  ~description:"Queued"
                  ~title:(Printf.sprintf "terrateam %s post-hooks" unified_run_type)
                  ~status:Status.Queued
                  repo;
              ]
            in
            let dirspace_checks =
              let module Ds = Terrat_change.Dirspace in
              let module Dsf = Terrat_change.Dirspaceflow in
              CCList.map
                (fun { Dsf.dirspace = { Ds.dir; workspace; _ }; _ } ->
                  S.make_commit_check
                    ~description:"Queued"
                    ~title:(Printf.sprintf "terrateam %s: %s %s" unified_run_type dir workspace)
                    ~status:Status.Queued
                    repo)
                dirspaces
            in
            let checks = aggregate @ dirspace_checks in
            create_commit_checks client repo ref_ checks

      let create_and_store_work_manifest
          t
          db
          repo_config
          pull_request
          all_matches
          matches
          denied_dirspaces
          operation =
        let open Abbs_future_combinators.Infix_result_monad in
        let module Run_type = Terrat_work_manifest2.Run_type in
        let module Wm = Terrat_work_manifest2 in
        Abb.Future.return (dirspaceflows_of_changes repo_config all_matches)
        >>= fun all_dirspaceflows ->
        store_dirspaceflows
          ~base_ref:(S.Pull_request.base_ref pull_request)
          ~branch_ref:(S.Pull_request.branch_ref pull_request)
          db
          (S.Pull_request.repo pull_request)
          all_dirspaceflows
        >>= fun () ->
        Abb.Future.return (dirspaceflows_of_changes repo_config matches)
        >>= fun dirspaceflows ->
        let changes =
          let module Dsf = Terrat_change.Dirspaceflow in
          CCList.map
            (fun ({ Dsf.workflow; _ } as dsf) ->
              { dsf with Dsf.workflow = CCOption.map (fun Dsf.Workflow.{ idx; _ } -> idx) workflow })
            dirspaceflows
        in
        let denied_dirspaces =
          let module Ac = Terrat_access_control in
          let module Cm = Terrat_change_match in
          CCList.map
            (fun { Ac.R.Deny.change_match = { Cm.dirspace; _ }; policy } ->
              { Wm.Deny.dirspace; policy })
            denied_dirspaces
        in
        (match t.work_manifest with
        | Some wm -> Abb.Future.return (Ok { wm with Wm.changes; denied_dirspaces })
        | None ->
            let hash =
              let module St = Terrat_pull_request.State in
              match S.Pull_request.state pull_request with
              | St.Open _ | St.Closed -> S.Ref.to_string (S.Pull_request.branch_ref pull_request)
              | St.Merged { St.Merged.merged_hash; _ } -> merged_hash
            in
            let work_manifest =
              {
                Wm.base_hash = S.Ref.to_string (S.Pull_request.base_ref pull_request);
                changes;
                completed_at = None;
                created_at = ();
                denied_dirspaces;
                hash;
                id = ();
                src = Wm.Kind.Pull_request pull_request;
                run_id = ();
                run_type = Tf_operation.to_run_type operation;
                state = ();
                tag_query = S.Event.Terraform.tag_query t.event;
                user = Some (S.Event.Terraform.user t.event);
              }
            in
            Metrics.Dirspaces_per_work_manifest_histogram.observe
              (Metrics.dirspaces_per_work_manifest (Run_type.to_string work_manifest.Wm.run_type))
              (CCFloat.of_int (CCList.length changes));
            create_work_manifest db work_manifest)
        >>= fun work_manifest ->
        Prmths.Counter.inc_one
          (Metrics.stored_work_manifests_total (Run_type.to_string work_manifest.Wm.run_type));
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : CREATED_WORK_MANIFEST : id=%a"
              (S.Event.Terraform.request_id t.event)
              Uuidm.pp
              work_manifest.Wm.id);
        update_work_manifest db work_manifest
        >>= fun work_manifest ->
        create_queued_commit_checks
          t.client
          (S.Event.Terraform.repo t.event)
          (S.Pull_request.branch_ref pull_request)
          work_manifest
        >>= fun () ->
        Abb.Future.return (Ok (S.Event.Terraform.created_work_manifest t.event work_manifest))

      let maybe_create_pending_applies client pull_request = function
        | [] ->
            (* No dirspaces, don't create anything *)
            Abb.Future.return (Ok ())
        | dirspaces ->
            let open Abbs_future_combinators.Infix_result_monad in
            fetch_commit_checks
              client
              (S.Pull_request.repo pull_request)
              (S.Pull_request.branch_ref pull_request)
            >>= fun commit_checks ->
            let commit_check_titles =
              commit_checks
              |> CCList.map (fun Terrat_commit_check.{ title; _ } -> title)
              |> String_set.of_list
            in
            let missing_commit_checks =
              dirspaces
              |> CCList.filter_map
                   (fun
                     Terrat_change_match.
                       {
                         dirspace = Terrat_change.Dirspace.{ dir; workspace };
                         when_modified = Terrat_repo_config.When_modified.{ autoapply; _ };
                         _;
                       }
                   ->
                     let name = Printf.sprintf "terrateam apply: %s %s" dir workspace in
                     if (not autoapply) && not (String_set.mem name commit_check_titles) then
                       Some
                         (S.make_commit_check
                            ~description:"Waiting"
                            ~title:(Printf.sprintf "terrateam apply: %s %s" dir workspace)
                            ~status:Terrat_commit_check.Status.Queued
                            (S.Pull_request.repo pull_request))
                     else None)
            in
            create_commit_checks
              client
              (S.Pull_request.repo pull_request)
              (S.Pull_request.branch_ref pull_request)
              missing_commit_checks

      let eval_plan t db access_control tag_query_matches all_matches pull_request repo_config mode
          =
        let module D = Terrat_access_control.R.Deny in
        let module Cm = Terrat_change_match in
        let matches =
          match mode with
          | Tf_operation.Auto ->
              CCList.filter
                (fun Terrat_change_match.
                       {
                         when_modified =
                           Terrat_repo_config.When_modified.{ autoplan; autoplan_draft_pr; _ };
                         _;
                       } ->
                  autoplan && ((not (S.Pull_request.is_draft_pr pull_request)) || autoplan_draft_pr))
                tag_query_matches
          | Tf_operation.Manual -> tag_query_matches
        in
        let open Abbs_future_combinators.Infix_result_monad in
        missing_autoplan_matches t.event db pull_request matches mode
        >>= function
        | [] when mode = Tf_operation.Auto ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : NOOP : AUTOPLAN_NO_MISSING_MATCHES : draft=%s"
                  (S.Event.Terraform.request_id t.event)
                  (Bool.to_string (S.Pull_request.is_draft_pr pull_request)));
            Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
        | matches -> (
            let open Abb.Future.Infix_monad in
            Access_control_engine.eval_tf_operation access_control matches `Plan
            >>= function
            | Ok Terrat_access_control.R.{ pass = []; deny = _ :: _ as deny }
              when not (Access_control_engine.plan_require_all_dirspace_access access_control) ->
                let open Abbs_future_combinators.Infix_result_monad in
                (* In this case all have been denied, but not all dirspaces must have
                   access, however this is treated as special because no work will be done
                   so a special message should be given to the usr. *)
                publish_msg
                  t
                  (Msg.Access_control_denied
                     (Access_control_engine.policy_branch access_control, `All_dirspaces deny))
                >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
            | Ok Terrat_access_control.R.{ pass; deny }
              when CCList.is_empty deny
                   || not (Access_control_engine.plan_require_all_dirspace_access access_control)
              -> (
                (* All have passed or any that we do not require all to pass *)
                let matches = pass in
                match (S.Pull_request.state pull_request, mode, matches) with
                | _, Tf_operation.Auto, [] ->
                    Logs.info (fun m ->
                        m
                          "EVALUATOR : %s : NOOP : AUTOPLAN_NO_MATCHES : draft=%s"
                          (S.Event.Terraform.request_id t.event)
                          (Bool.to_string (S.Pull_request.is_draft_pr pull_request)));
                    Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
                | _, _, [] ->
                    let open Abbs_future_combinators.Infix_result_monad in
                    Logs.info (fun m ->
                        m
                          "EVALUATOR : %s : NOOP : PLAN_NO_MATCHING_DIRSPACES"
                          (S.Event.Terraform.request_id t.event));
                    publish_msg t Msg.Plan_no_matching_dirspaces
                    >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
                | Terrat_pull_request.State.(Open Open_status.Merge_conflict), _, _ ->
                    Abb.Future.return (Error `Merge_conflict)
                | _, _, _ -> (
                    let open Abbs_future_combinators.Infix_result_monad in
                    let dirspaces =
                      CCList.map (fun Terrat_change_match.{ dirspace; _ } -> dirspace) matches
                    in
                    test_can_perform_operation
                      t.event
                      db
                      pull_request
                      dirspaces
                      (Tf_operation.Plan mode)
                    >>= function
                    | `Valid ->
                        create_and_store_work_manifest
                          t
                          db
                          repo_config
                          pull_request
                          all_matches
                          matches
                          deny
                          (Tf_operation.Plan mode)
                        >>= fun ret ->
                        let module Rc = Terrat_repo_config.Version_1 in
                        let module Ar = Rc.Apply_requirements in
                        let apply_requirements =
                          CCOption.get_or
                            ~default:(Rc.Apply_requirements.make ())
                            repo_config.Rc.apply_requirements
                        in
                        (if apply_requirements.Ar.create_pending_apply_check then
                           maybe_create_pending_applies t.client pull_request all_matches
                         else Abb.Future.return (Ok ()))
                        >>= fun () -> Abb.Future.return (Ok ret)
                    | `Conflicting_work_manifests wms ->
                        publish_msg t (Msg.Conflicting_work_manifests wms)
                        >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
                    | `Account_expired ->
                        publish_msg t Msg.Account_expired
                        >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))))
            | Ok Terrat_access_control.R.{ deny; _ } ->
                let open Abbs_future_combinators.Infix_result_monad in
                publish_msg
                  t
                  (Msg.Access_control_denied
                     (Access_control_engine.policy_branch access_control, `Dirspaces deny))
                >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
            | Error `Error ->
                let open Abbs_future_combinators.Infix_result_monad in
                publish_msg
                  t
                  (Msg.Access_control_denied
                     (Access_control_engine.policy_branch access_control, `Lookup_err))
                >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
            | Error (#Terrat_tag_query_ast.err as err) ->
                let open Abbs_future_combinators.Infix_result_monad in
                Logs.err (fun m ->
                    m
                      "EVALUATOR : %s : TAG_QUERY : %a"
                      (S.Event.Terraform.request_id t.event)
                      Terrat_tag_query_ast.pp_err
                      err);
                publish_msg t (Msg.Tag_query_err err)
                >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
            | Error (`Invalid_query query) ->
                let open Abbs_future_combinators.Infix_result_monad in
                publish_msg
                  t
                  (Msg.Access_control_denied
                     (Access_control_engine.policy_branch access_control, `Invalid_query query))
                >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event)))

      let tf_operation_of_apply_operation = function
        | `Apply mode -> Tf_operation.Apply mode
        | `Apply_autoapprove -> Tf_operation.Apply_autoapprove
        | `Apply_force -> Tf_operation.Apply_force

      let eval_apply' t db matches all_matches pull_request repo_config operation deny =
        let module D = Terrat_access_control.R.Deny in
        let module Cm = Terrat_change_match in
        let open Abbs_future_combinators.Infix_result_monad in
        match (operation, matches) with
        | `Apply Tf_operation.Auto, [] ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : NOOP : AUTOAPPLY_NO_MATCHES"
                  (S.Event.Terraform.request_id t.event));
            Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
        | _, [] ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : NOOP : APPLY_NO_MATCHING_DIRSPACES"
                  (S.Event.Terraform.request_id t.event));
            publish_msg t Msg.Apply_no_matching_dirspaces
            >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
        | _, _ -> (
            Abb.Future.return (dirspaceflows_of_changes repo_config all_matches)
            >>= fun all_match_dirspaceflows ->
            query_dirspaces_owned_by_other_pull_requests
              db
              pull_request
              (CCList.map Terrat_change.Dirspaceflow.to_dirspace all_match_dirspaceflows)
            >>= function
            | [] when operation = `Apply_autoapprove -> (
                create_and_store_work_manifest
                  t
                  db
                  repo_config
                  pull_request
                  matches
                  matches
                  deny
                  (tf_operation_of_apply_operation operation)
                >>= function
                | r when operation = `Apply Tf_operation.Auto ->
                    let open Abb.Future.Infix_monad in
                    publish_msg t Msg.Autoapply_running >>= fun _ -> Abb.Future.return (Ok r)
                | r -> Abb.Future.return (Ok r))
            | [] -> (
                (* None of the dirspaces are owned by another PR, we can proceed *)
                query_dirspaces_without_valid_plans
                  db
                  pull_request
                  (CCList.map (fun Terrat_change_match.{ dirspace; _ } -> dirspace) matches)
                >>= function
                | [] -> (
                    let dirspaces =
                      CCList.map (fun Terrat_change_match.{ dirspace; _ } -> dirspace) matches
                    in
                    test_can_perform_operation
                      t.event
                      db
                      pull_request
                      dirspaces
                      (tf_operation_of_apply_operation operation)
                    >>= function
                    | `Valid -> (
                        (* All are ready to be applied *)
                        create_and_store_work_manifest
                          t
                          db
                          repo_config
                          pull_request
                          matches
                          matches
                          deny
                          (tf_operation_of_apply_operation operation)
                        >>= function
                        | r when operation = `Apply Tf_operation.Auto ->
                            let open Abb.Future.Infix_monad in
                            publish_msg t Msg.Autoapply_running
                            >>= fun _ -> Abb.Future.return (Ok r)
                        | r -> Abb.Future.return (Ok r))
                    | `Conflicting_work_manifests wms ->
                        publish_msg t (Msg.Conflicting_work_manifests wms)
                        >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
                    | `Account_expired ->
                        publish_msg t Msg.Account_expired
                        >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event)))
                | dirspaces ->
                    (* Some are missing plans *)
                    publish_msg t (Msg.Missing_plans dirspaces)
                    >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event)))
            | owned_dirspaces ->
                (* Some are owned by another PR, abort *)
                publish_msg t (Msg.Dirspaces_owned_by_other_pull_request owned_dirspaces)
                >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event)))

      let eval_apply
          t
          db
          access_control
          tag_query_matches
          all_matches
          pull_request
          repo_config
          operation =
        let open Abbs_future_combinators.Infix_result_monad in
        query_unapplied_dirspaces db pull_request
        >>= fun missing_dirspaces ->
        (* Filter only those missing *)
        let tag_query_matches =
          CCList.filter
            (fun Terrat_change_match.{ dirspace; _ } ->
              CCList.mem ~eq:Terrat_change.Dirspace.equal dirspace missing_dirspaces)
            tag_query_matches
        in
        (* To perform an apply we need:

           1. Plans for all of the dirspaces we are going to run.  This
           also means that the plan also has happened after any of the
           most recent applies to that dirspace.

           2. Make sure no other pull requests own the any of the
           dirspaces that this pull request touches. *)
        let matches =
          match operation with
          | `Apply Tf_operation.Auto ->
              CCList.filter
                (fun Terrat_change_match.
                       { when_modified = Terrat_repo_config.When_modified.{ autoapply; _ }; _ } ->
                  autoapply)
                tag_query_matches
          | `Apply Tf_operation.Manual | `Apply_autoapprove | `Apply_force -> tag_query_matches
        in
        check_apply_requirements t.event t.client pull_request repo_config
        >>= fun apply_requirements ->
        let passed_apply_requirements = S.Apply_requirements.passed apply_requirements in
        let access_control_run_type =
          match operation with
          | `Apply _ ->
              `Apply
                (CCList.flat_map
                   (function
                     | Terrat_pull_request_review.{ user = Some user; _ } -> [ user ]
                     | _ -> [])
                   (S.Apply_requirements.approved_reviews apply_requirements))
          | (`Apply_autoapprove | `Apply_force) as op -> op
        in
        let open Abb.Future.Infix_monad in
        Access_control_engine.eval_tf_operation access_control matches access_control_run_type
        >>= function
        | Ok access_control_result -> (
            match (operation, access_control_result) with
            | (`Apply _ | `Apply_autoapprove), _ when not passed_apply_requirements ->
                let open Abbs_future_combinators.Infix_result_monad in
                Logs.info (fun m ->
                    m "EVALUATOR : %s : PR_NOT_APPLIABLE" (S.Event.Terraform.request_id t.event));
                publish_msg t (Msg.Pull_request_not_appliable (pull_request, apply_requirements))
                >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
            | _, Terrat_access_control.R.{ pass = []; deny = _ :: _ as deny }
              when not (Access_control_engine.apply_require_all_dirspace_access access_control) ->
                let open Abbs_future_combinators.Infix_result_monad in
                (* In this case all have been denied, but not all dirspaces must have
                   access, however this is treated as special because no work will be done
                   so a special message should be given to the usr. *)
                publish_msg
                  t
                  (Msg.Access_control_denied
                     (Access_control_engine.policy_branch access_control, `All_dirspaces deny))
                >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
            | _, Terrat_access_control.R.{ pass; deny }
              when CCList.is_empty deny
                   || not (Access_control_engine.apply_require_all_dirspace_access access_control)
              ->
                (* All have passed or any that we do not require all to pass *)
                let matches = pass in
                eval_apply' t db matches all_matches pull_request repo_config operation deny
            | _, Terrat_access_control.R.{ deny; _ } ->
                let open Abbs_future_combinators.Infix_result_monad in
                publish_msg
                  t
                  (Msg.Access_control_denied
                     (Access_control_engine.policy_branch access_control, `Dirspaces deny))
                >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event)))
        | Error `Error ->
            let open Abbs_future_combinators.Infix_result_monad in
            publish_msg
              t
              (Msg.Access_control_denied
                 (Access_control_engine.policy_branch access_control, `Lookup_err))
            >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
        | Error (#Terrat_tag_query_ast.err as err) ->
            let open Abbs_future_combinators.Infix_result_monad in
            publish_msg t (Msg.Tag_query_err err)
            >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
        | Error (`Invalid_query query) ->
            let open Abbs_future_combinators.Infix_result_monad in
            publish_msg
              t
              (Msg.Access_control_denied
                 (Access_control_engine.policy_branch access_control, `Invalid_query query))
            >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))

      let eval_operation t access_control pull_request repo_config repo_tree index =
        let open Abbs_future_combinators.Infix_result_monad in
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : PULL_REQUEST : NUM_DIFF : %d"
              (S.Event.Terraform.request_id t.event)
              (CCList.length (S.Pull_request.diff pull_request)));
        S.Event.Terraform.with_db t.event ~f:(fun db ->
            S.Db.tx db ~f:(fun () ->
                (* Collect any changes that have been applied outside of the current
                   state of the PR.  For example, we made a change to dir1 and dir2,
                   applied dir1, then we updated our PR to revert dir1, we would
                   want to be able to plan and apply dir1 again even though it
                   doesn't look like dir1 changes. *)
                query_pull_request_out_of_change_applies db pull_request
                >>= fun out_of_change_applies ->
                Abb.Future.return
                  (compute_matches
                     ~repo_config
                     ~tag_query:(S.Event.Terraform.tag_query t.event)
                     ~out_of_change_applies
                     ~diff:(S.Pull_request.diff pull_request)
                     ~repo_tree
                     ~index
                     ())
                >>= fun (tag_query_matches, all_matches) ->
                Logs.info (fun m ->
                    m
                      "EVALUATOR : %s : NUM_MATCHES : all_matches=%d : tag_query_matches=%d"
                      (S.Event.Terraform.request_id t.event)
                      (CCList.length all_matches)
                      (CCList.length tag_query_matches));
                let dirs =
                  all_matches
                  |> CCList.map
                       (fun
                         Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; _ } ->
                         dir)
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
                let missing_dirs = Dir_set.diff dirs existing_dirs in
                Logs.info (fun m ->
                    m
                      "EVALUATOR : %s : MISSING_DIRS : num=%d"
                      (S.Event.Terraform.request_id t.event)
                      (Dir_set.cardinal missing_dirs));
                (* This is different behaviour than evaluator1. *)
                let all_matches =
                  all_matches
                  |> CCList.filter
                       (fun
                         Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; _ } ->
                         Dir_set.mem dir existing_dirs)
                in
                let tag_query_matches =
                  tag_query_matches
                  |> CCList.filter
                       (fun
                         Terrat_change_match.{ dirspace = Terrat_change.Dirspace.{ dir; _ }; _ } ->
                         Dir_set.mem dir existing_dirs)
                in
                Prmths.Counter.inc_one
                  (Metrics.operations_total
                     (Tf_operation.to_string (S.Event.Terraform.tf_operation t.event)));
                match S.Event.Terraform.tf_operation t.event with
                | Tf_operation.Plan mode ->
                    Abbs_time_it.run
                      (log_time (S.Event.Terraform.request_id t.event) "PROCESS_PLAN")
                      (fun () ->
                        eval_plan
                          t
                          db
                          access_control
                          tag_query_matches
                          all_matches
                          pull_request
                          repo_config
                          mode)
                | Tf_operation.Apply mode ->
                    Abbs_time_it.run
                      (log_time (S.Event.Terraform.request_id t.event) "PROCESS_APPLY")
                      (fun () ->
                        eval_apply
                          t
                          db
                          access_control
                          tag_query_matches
                          all_matches
                          pull_request
                          repo_config
                          (`Apply mode))
                | Tf_operation.Apply_autoapprove ->
                    Abbs_time_it.run
                      (log_time (S.Event.Terraform.request_id t.event) "PROCESS_APPLY_AUTOAPPROVE")
                      (fun () ->
                        eval_apply
                          t
                          db
                          access_control
                          tag_query_matches
                          all_matches
                          pull_request
                          repo_config
                          `Apply_autoapprove)
                | Tf_operation.Apply_force ->
                    Abbs_time_it.run
                      (log_time (S.Event.Terraform.request_id t.event) "PROCESS_APPLY_FORCE")
                      (fun () ->
                        eval_apply
                          t
                          db
                          access_control
                          tag_query_matches
                          all_matches
                          pull_request
                          repo_config
                          `Apply_force)))

      let eval_change t remote_repo repo_config repo_default_config repo_tree pull_request index =
        let access_control =
          Access_control_engine.make
            ~request_id:(S.Event.Terraform.request_id t.event)
            ~ctx:(S.Event.Terraform.create_access_control_ctx t.event t.client)
            ~repo_config:repo_default_config
            ~user:(S.Event.Terraform.user t.event)
            ~policy_branch:(S.Remote_repo.default_branch remote_repo)
            ()
        in
        match S.Pull_request.state pull_request with
        | Terrat_pull_request.State.(Open _ | Merged _) -> (
            let open Abb.Future.Infix_monad in
            Access_control_engine.eval_repo_config access_control (S.Pull_request.diff pull_request)
            >>= function
            | Ok None ->
                Prmths.Counter.inc_one
                  (Metrics.access_control_total
                     ~t:(Tf_operation.to_string (S.Event.Terraform.tf_operation t.event))
                     ~r:"allowed");
                eval_operation
                  t
                  access_control
                  pull_request
                  repo_config
                  repo_tree
                  (CCOption.get_or ~default:Terrat_change_match.Index.empty index)
            | Ok (Some match_list) ->
                let open Abbs_future_combinators.Infix_result_monad in
                Logs.info (fun m ->
                    m
                      "EVALUATOR : %s : ACCESS_CONTROL_DENIED : TERRATEAM_CONFIG_UPDATE"
                      (S.Event.Terraform.request_id t.event));
                publish_msg
                  t
                  (Msg.Access_control_denied
                     ( Access_control_engine.policy_branch access_control,
                       `Terrateam_config_update match_list ))
                >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
            | Error `Error ->
                let open Abbs_future_combinators.Infix_result_monad in
                Logs.info (fun m ->
                    m
                      "EVALUATOR : %s : ACCESS_CONTROL_DENIED : LOOKUP_ERR"
                      (S.Event.Terraform.request_id t.event));
                Prmths.Counter.inc_one
                  (Metrics.access_control_total
                     ~t:(Tf_operation.to_string (S.Event.Terraform.tf_operation t.event))
                     ~r:"denied");
                publish_msg
                  t
                  (Msg.Access_control_denied
                     (Access_control_engine.policy_branch access_control, `Lookup_err))
                >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event))
            | Error (`Invalid_query query) ->
                let open Abbs_future_combinators.Infix_result_monad in
                Logs.info (fun m ->
                    m
                      "EVALUATOR : %s : ACCESS_CONTROL_DENIED : INVALID_QUERY : %s"
                      (S.Event.Terraform.request_id t.event)
                      query);
                Prmths.Counter.inc_one
                  (Metrics.access_control_total
                     ~t:(Tf_operation.to_string (S.Event.Terraform.tf_operation t.event))
                     ~r:"denied");
                publish_msg
                  t
                  (Msg.Access_control_denied
                     ( Access_control_engine.policy_branch access_control,
                       `Terrateam_config_update_bad_query query ))
                >>= fun () -> Abb.Future.return (Ok (S.Event.Terraform.noop t.event)))
        | Terrat_pull_request.State.Closed ->
            Logs.info (fun m ->
                m "EVALUATOR : %s : NOOP : PR_CLOSED" (S.Event.Terraform.request_id t.event));
            Abb.Future.return (Ok (S.Event.Terraform.noop t.event))

      let eval_index t remote_repo repo_config repo_default_config repo_tree pull_request =
        let open Abbs_future_combinators.Infix_result_monad in
        let module Wm = Terrat_work_manifest2 in
        Abb.Future.return
          (Terrat_change_match.synthesize_dir_config
             ~index:Terrat_change_match.Index.empty
             ~file_list:repo_tree
             repo_config)
        >>= fun dirs ->
        let matches =
          Terrat_change_match.match_diff_list
            dirs
            (CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) repo_tree)
        in
        Abb.Future.return (dirspaceflows_of_changes repo_config matches)
        >>= function
        | [] ->
            Logs.info (fun m ->
                m "EVALUATOR : %s : INDEX : NO_CHANGES" (S.Event.Terraform.request_id t.event));
            (* If there is no index to be generated, then follow through with
               the rest of the standard workflow, that way we get the rest of
               the processing and any error messages. *)
            eval_change t remote_repo repo_config repo_default_config repo_tree pull_request None
        | _ :: _ ->
            (* Only do something if there are any matches *)
            let work_manifest =
              {
                Wm.base_hash = S.Ref.to_string (S.Pull_request.base_ref pull_request);
                changes = [];
                completed_at = None;
                created_at = ();
                denied_dirspaces = [];
                hash = S.Ref.to_string (S.Pull_request.branch_ref pull_request);
                id = ();
                run_id = ();
                run_type = Tf_operation.to_run_type (S.Event.Terraform.tf_operation t.event);
                src = Wm.Kind.Pull_request pull_request;
                state = ();
                tag_query = S.Event.Terraform.tag_query t.event;
                user = Some (S.Event.Terraform.user t.event);
              }
            in
            S.Event.Terraform.with_db t.event ~f:(fun db -> S.create_work_manifest db work_manifest)
            >>= fun work_manifest ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : INDEX_WORK_MANIFEST : id=%a"
                  (S.Event.Terraform.request_id t.event)
                  Uuidm.pp
                  work_manifest.Wm.id);
            Abb.Future.return (Ok (S.Event.Terraform.created_work_manifest t.event work_manifest))

      let run t =
        let module V1 = Terrat_repo_config.Version_1 in
        let open Abbs_future_combinators.Infix_result_monad in
        fetch_pull_request
          (S.Event.Terraform.account t.event)
          t.client
          (S.Event.Terraform.repo t.event)
          (S.Event.Terraform.pull_number t.event)
        >>= fun pull_request ->
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : PULL_REQUEST : base_branch_name=%s : base_ref=%s : branch_name=%s \
               : branch_ref=%s : provisional_merge_ref=%s"
              (S.Client.request_id t.client)
              (S.Ref.to_string (S.Pull_request.base_branch_name pull_request))
              (S.Ref.to_string (S.Pull_request.base_ref pull_request))
              (S.Ref.to_string (S.Pull_request.branch_name pull_request))
              (S.Ref.to_string (S.Pull_request.branch_ref pull_request))
              (CCOption.map_or
                 ~default:""
                 S.Ref.to_string
                 (S.Pull_request.provisional_merge_ref pull_request)));
        S.Event.Terraform.with_db t.event ~f:(fun db -> store_pull_request db pull_request)
        >>= fun () ->
        let repo = S.Event.Terraform.repo t.event in
        fetch_remote_repo t.client repo
        >>= fun remote_repo ->
        fetch_change_data t.event t.client remote_repo pull_request
        >>= function
        | ( ({ V1.enabled = true; indexer = Some { V1.Indexer.enabled = true; _ }; _ } as repo_config),
            repo_default_config,
            repo_tree,
            None ) ->
            (* Index required but does not exist *)
            eval_index t remote_repo repo_config repo_default_config repo_tree pull_request
        | ({ V1.enabled = true; _ } as repo_config), repo_default_config, repo_tree, index ->
            eval_change t remote_repo repo_config repo_default_config repo_tree pull_request index
        | _, _, _, _ ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : NOOP : REPO_CONFIG_DISABLED"
                  (S.Event.Terraform.request_id t.event));
            Abb.Future.return (Ok (S.Event.Terraform.noop t.event))

      let eval'' t =
        let open Abbs_future_combinators.Infix_result_monad in
        S.Event.Terraform.with_db t.event ~f:(fun db ->
            S.query_account_status db (S.Event.Terraform.account t.event))
        >>= function
        | `Active | `Expired -> run t
        | `Disabled ->
            Prmths.Counter.inc_one Metrics.op_on_account_disabled_total;
            Logs.debug (fun m ->
                m "EVALUATOR : %s : ACCOUNT_DISABLED" (S.Event.Terraform.request_id t.event));
            Abb.Future.return (Ok (S.Event.Terraform.noop t.event))

      let handle_dest_branch_err t pull_request =
        let module O = Tf_operation in
        match S.Event.Terraform.tf_operation t.event with
        | O.Plan O.Auto | O.Apply O.Auto ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : DEST_BRANCH_NOT_VALID_BRANCH : branch=%s"
                  (S.Event.Terraform.request_id t.event)
                  (S.Ref.to_string (S.Pull_request.base_branch_name pull_request)));
            Abb.Future.return (Error `Error)
        | O.Apply _ | O.Apply_autoapprove | O.Apply_force | O.Plan _ ->
            let open Abb.Future.Infix_monad in
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : DEST_BRANCH_NOT_VALID_BRANCH_EXPLICIT : branch=%s"
                  (S.Event.Terraform.request_id t.event)
                  (S.Ref.to_string (S.Pull_request.base_branch_name pull_request)));
            Abbs_future_combinators.ignore (publish_msg t (Msg.Dest_branch_no_match pull_request))
            >>= fun () -> Abb.Future.return (Error `Error)

      let handle_source_branch_err t pull_request =
        let module O = Tf_operation in
        match S.Event.Terraform.tf_operation t.event with
        | O.Plan O.Auto | O.Apply O.Auto ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : SOURCE_BRANCH_NOT_VALID_BRANCH : branch=%s"
                  (S.Event.Terraform.request_id t.event)
                  (S.Ref.to_string (S.Pull_request.branch_name pull_request)));
            Abb.Future.return (Error `Error)
        | O.Apply _ | O.Apply_autoapprove | O.Apply_force | O.Plan _ ->
            let open Abb.Future.Infix_monad in
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : SOURCE_BRANCH_NOT_VALID_BRANCH_EXPLICIT : branch=%s"
                  (S.Event.Terraform.request_id t.event)
                  (S.Ref.to_string (S.Pull_request.branch_name pull_request)));
            (* FIXME should probably be a special error message *)
            Abbs_future_combinators.ignore (publish_msg t (Msg.Dest_branch_no_match pull_request))
            >>= fun () -> Abb.Future.return (Error `Error)

      let eval' ?work_manifest event =
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : EVAL : TF : account=%s : repo=%s : pull_number=%d : op=%s : \
               tag_query=%s : user=%s"
              (S.Event.Terraform.request_id event)
              (S.Account.to_string (S.Event.Terraform.account event))
              (S.Repo.to_string (S.Event.Terraform.repo event))
              (S.Event.Terraform.pull_number event)
              (Tf_operation.to_string (S.Event.Terraform.tf_operation event))
              (Terrat_tag_query.to_string (S.Event.Terraform.tag_query event))
              (S.Event.Terraform.user event));
        let open Abb.Future.Infix_monad in
        create_client
          (S.Event.Terraform.request_id event)
          (S.Event.Terraform.config event)
          (S.Event.Terraform.account event)
        >>= function
        | Ok client ->
            let t = { client; event; work_manifest } in
            Abb.Future.await_bind
              (function
                | `Det v -> (
                    let open Abb.Future.Infix_monad in
                    match v with
                    | Ok _ as ret -> Abb.Future.return ret
                    | Error `Error -> Abb.Future.return (Error `Error)
                    | Error (#Pgsql_io.err as err) ->
                        Logs.err (fun m ->
                            m
                              "EVALUATOR : %s : DB : %a"
                              (S.Event.Terraform.request_id t.event)
                              Pgsql_io.pp_err
                              err);
                        Abb.Future.return (Error `Error)
                    | Error (#Pgsql_pool.err as err) ->
                        Logs.err (fun m ->
                            m
                              "EVALUATOR : %s : DB : %a"
                              (S.Event.Terraform.request_id t.event)
                              Pgsql_pool.pp_err
                              err);
                        Abb.Future.return (Error `Error)
                    | Error (`Bad_glob s) ->
                        Logs.err (fun m ->
                            m
                              "EVALUATOR : %s : BAD_GLOB : %s"
                              (S.Event.Terraform.request_id t.event)
                              s);
                        Abbs_future_combinators.ignore (publish_msg t (Msg.Bad_glob s))
                        >>= fun () -> Abb.Future.return (Error `Error)
                    | Error `Merge_conflict ->
                        Prmths.Counter.inc_one Metrics.op_on_pull_request_not_mergeable;
                        Logs.debug (fun m ->
                            m
                              "EVALUATOR : %s : MERGE_CONFLICT"
                              (S.Event.Terraform.request_id t.event));
                        Abbs_future_combinators.ignore
                          (publish_msg t Msg.Pull_request_not_mergeable)
                        >>= fun () -> Abb.Future.return (Error `Error)
                    | Error (#Terrat_tag_query_ast.err as err) ->
                        Logs.err (fun m ->
                            m
                              "EVALUATOR : %s : TAG_QUERY_ERR : %a"
                              (S.Event.Terraform.request_id event)
                              Terrat_tag_query_ast.pp_err
                              err);
                        Abbs_future_combinators.ignore (publish_msg t (Msg.Tag_query_err err))
                        >>= fun () -> Abb.Future.return (Error `Error)
                    | Error (`No_matching_dest_branch pull_request) ->
                        handle_dest_branch_err t pull_request
                    | Error (`No_matching_source_branch pull_request) ->
                        handle_source_branch_err t pull_request)
                | `Aborted ->
                    Prmths.Counter.inc_one Metrics.aborted_errors_total;
                    Logs.err (fun m ->
                        m "EVALUATOR : %s : ABORTED" (S.Event.Terraform.request_id event));
                    Abb.Future.return (Error `Error)
                | `Exn (exn, bt_opt) ->
                    Prmths.Counter.inc_one Metrics.exn_errors_total;
                    Logs.err (fun m ->
                        m
                          "EVALUATOR : %s : EXN : %s : %s"
                          (S.Event.Terraform.request_id event)
                          (Printexc.to_string exn)
                          (CCOption.map_or ~default:"" Printexc.raw_backtrace_to_string bt_opt));
                    Abb.Future.return (Error `Error))
              (Metrics.DefaultHistogram.time Metrics.eval_duration_seconds (fun () -> eval'' t))
        | Error `Error ->
            Logs.err (fun m ->
                m "EVALUATOR : %s : CREATE_CLIENT_FAILED" (S.Event.Terraform.request_id event));
            Abb.Future.return (Error `Error)

      let eval event = eval' ?work_manifest:None event
    end

    module Initiate = struct
      let maybe_publish_msg t work_manifest msg =
        let module Wm = Terrat_work_manifest2 in
        match work_manifest.Wm.src with
        | Wm.Kind.Pull_request pr ->
            let open Abbs_future_combinators.Infix_result_monad in
            create_client
              (S.Event.Initiate.request_id t)
              (S.Event.Initiate.config t)
              (S.Pull_request.account pr)
            >>= fun client ->
            let publish =
              S.Publish_msg.make
                ~client
                ~pull_number:(S.Pull_request.id pr)
                ~repo:(S.Pull_request.repo pr)
                ~user:""
                ()
            in
            S.Publish_msg.publish_msg publish msg
            >>= fun () ->
            let open Abb.Future.Infix_monad in
            S.Event.Initiate.done_ t work_manifest >>= fun r -> Abb.Future.return (Ok r)
        | Wm.Kind.Drift _ | Wm.Kind.Index _ ->
            let open Abb.Future.Infix_monad in
            S.Event.Initiate.done_ t work_manifest >>= fun r -> Abb.Future.return (Ok r)

      let compute_changes repo_config repo_tree index =
        let open CCResult.Infix in
        Terrat_change_match.synthesize_dir_config
          ~index:Terrat_change_match.Index.empty
          ~file_list:repo_tree
          repo_config
        >>= fun dirs ->
        let matches =
          Terrat_change_match.match_diff_list
            dirs
            (CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) repo_tree)
        in
        dirspaceflows_of_changes repo_config matches
        >>= fun dirspaceflows ->
        let module Dsf = Terrat_change.Dirspaceflow in
        Ok
          (CCList.map
             (fun ({ Dsf.workflow; _ } as dsf) ->
               {
                 dsf with
                 Dsf.workflow = CCOption.map (fun Dsf.Workflow.{ idx; _ } -> idx) workflow;
               })
             dirspaceflows)

      let update_work_manifest_with_index db repo_config repo_tree index work_manifest =
        let open Abbs_future_combinators.Infix_result_monad in
        Abb.Future.return (compute_changes repo_config repo_tree index)
        >>= function
        | [] ->
            (* If there are no changes, then return the work manifest unmolested *)
            Abb.Future.return (Ok (Some work_manifest))
        | changes ->
            let work_manifest = { work_manifest with Terrat_work_manifest2.changes } in
            update_work_manifest db work_manifest
            >>= fun work_manifest -> Abb.Future.return (Ok (Some work_manifest))

      let make_index_work_manifest_if_changes
          request_id
          repo_config
          repo_tree
          index_run_kind
          work_manifest =
        let open CCResult.Infix in
        let module Wm = Terrat_work_manifest2 in
        compute_changes repo_config repo_tree Terrat_change_match.Index.empty
        >>= function
        | [] ->
            (* If there are no changes, then return the work manifest unmolested *)
            Logs.info (fun m ->
                m "EVALUATOR : %s : NO_CHANGES : id=%a" request_id Uuidm.pp work_manifest.Wm.id);
            Ok (Some work_manifest)
        | changes ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : MAKE_INDEX_WORK_MANIFEST : id=%a"
                  request_id
                  Uuidm.pp
                  work_manifest.Wm.id);
            Ok (Some { work_manifest with Wm.changes; src = Wm.Kind.Index index_run_kind })

      let maybe_make_index_work_manifest t account branch repo work_manifest =
        let module V1 = Terrat_repo_config.Version_1 in
        let open Abbs_future_combinators.Infix_result_monad in
        create_client (S.Event.Initiate.request_id t) (S.Event.Initiate.config t) account
        >>= fun client ->
        Abbs_future_combinators.Infix_result_app.(
          (fun repo_config tree index -> (repo_config, tree, index))
          <$> fetch_repo_config client repo branch
          <*> fetch_tree client repo (S.Event.Initiate.branch_ref t)
          <*> S.Event.Initiate.with_db t ~f:(fun db ->
                  query_index db account (S.Event.Initiate.branch_ref t)))
        >>= function
        | ( ({ V1.indexer = Some { V1.Indexer.enabled = true; _ }; _ } as repo_config),
            repo_tree,
            Some idx ) ->
            Logs.info (fun m ->
                m "EVALUATOR : %s : COMPUTE_CHANGES_WITH_INDEX" (S.Event.Initiate.request_id t));
            S.Event.Initiate.with_db t ~f:(fun db ->
                update_work_manifest_with_index db repo_config repo_tree idx work_manifest)
        | ( ({ V1.indexer = Some { V1.Indexer.enabled = true; _ }; _ } as repo_config),
            repo_tree,
            None ) ->
            Abb.Future.return
              (make_index_work_manifest_if_changes
                 (S.Event.Initiate.request_id t)
                 repo_config
                 repo_tree
                 (S.Index.make ~account ~branch ~repo ())
                 work_manifest)
        | { V1.indexer = Some { V1.Indexer.enabled = false; _ } | None; _ }, _, _ ->
            Logs.info (fun m ->
                m "EVALUATOR : %s : NO_INDEX_REQUIRED" (S.Event.Initiate.request_id t));
            Abb.Future.return (Ok (Some work_manifest))

      let maybe_make_index_for_pull_request_work_manifest
          t
          account
          branch
          repo
          pull_request
          work_manifest =
        let module V1 = Terrat_repo_config.Version_1 in
        let open Abbs_future_combinators.Infix_result_monad in
        create_client (S.Event.Initiate.request_id t) (S.Event.Initiate.config t) account
        >>= fun client ->
        Abbs_future_combinators.Infix_result_app.(
          (fun repo_config tree index -> (repo_config, tree, index))
          <$> fetch_repo_config client repo branch
          <*> fetch_tree client repo (S.Event.Initiate.branch_ref t)
          <*> S.Event.Initiate.with_db t ~f:(fun db ->
                  query_index db account (S.Event.Initiate.branch_ref t)))
        >>= function
        | { V1.indexer = Some { V1.Indexer.enabled = true; _ }; _ }, _, Some idx ->
            Logs.info (fun m ->
                m "EVALUATOR : %s : COMPUTE_CHANGES_WITH_INDEX" (S.Event.Initiate.request_id t));
            let event = S.Event.Initiate.terraform_event t pull_request work_manifest in
            Terraform.eval' ~work_manifest event
            >>= fun r -> Abb.Future.return (Ok (S.Event.Initiate.work_manifest_of_terraform_r r))
        | ( ({ V1.indexer = Some { V1.Indexer.enabled = true; _ }; _ } as repo_config),
            repo_tree,
            None ) ->
            Abb.Future.return
              (make_index_work_manifest_if_changes
                 (S.Event.Initiate.request_id t)
                 repo_config
                 repo_tree
                 (S.Index.make ~account ~branch ~repo ())
                 work_manifest)
        | { V1.indexer = Some { V1.Indexer.enabled = false; _ } | None; _ }, _, _ ->
            Logs.info (fun m ->
                m "EVALUATOR : %s : NO_INDEX_REQUIRED" (S.Event.Initiate.request_id t));
            Abb.Future.return (Ok (Some work_manifest))

      let maybe_require_index_work_manifest t =
        let module Wm = Terrat_work_manifest2 in
        function
        | { Wm.changes = _ :: _; _ } as wm ->
            (* If there are changes, it's because the work manifest is runnable. *)
            Abb.Future.return (Ok (Some wm))
        | { Wm.src = Wm.Kind.Pull_request pr; _ } as wm ->
            maybe_make_index_for_pull_request_work_manifest
              t
              (S.Pull_request.account pr)
              (S.Pull_request.branch_ref pr)
              (S.Pull_request.repo pr)
              pr
              wm
        | { Wm.src = Wm.Kind.Drift drift; _ } as wm ->
            maybe_make_index_work_manifest
              t
              (S.Drift.account drift)
              (S.Drift.branch drift)
              (S.Drift.repo drift)
              wm
        | { Wm.src = Wm.Kind.Index _; _ } as wm -> Abb.Future.return (Ok (Some wm))

      let maybe_update_commit_checks t =
        let module Wm = Terrat_work_manifest2 in
        function
        | { Wm.src = Wm.Kind.Pull_request pr; changes; run_type; hash = ref_; _ } ->
            let open Abbs_future_combinators.Infix_result_monad in
            let module Status = Terrat_commit_check.Status in
            let repo = S.Pull_request.repo pr in
            let unified_run_type =
              let module Urt = Terrat_work_manifest2.Unified_run_type in
              run_type |> Urt.of_run_type |> Urt.to_string
            in
            let aggregate =
              [
                S.make_commit_check
                  ~description:"Running"
                  ~title:(Printf.sprintf "terrateam %s pre-hooks" unified_run_type)
                  ~status:Status.Running
                  repo;
                S.make_commit_check
                  ~description:"Running"
                  ~title:(Printf.sprintf "terrateam %s post-hooks" unified_run_type)
                  ~status:Status.Running
                  repo;
              ]
            in
            let dirspace_checks =
              let module Ds = Terrat_change.Dirspace in
              let module Dsf = Terrat_change.Dirspaceflow in
              CCList.map
                (fun { Dsf.dirspace = { Ds.dir; workspace; _ }; _ } ->
                  S.make_commit_check
                    ~description:"Running"
                    ~title:(Printf.sprintf "terrateam %s: %s %s" unified_run_type dir workspace)
                    ~status:Status.Running
                    repo)
                changes
            in
            let checks = aggregate @ dirspace_checks in
            create_client
              (S.Event.Initiate.request_id t)
              (S.Event.Initiate.config t)
              (S.Pull_request.account pr)
            >>= fun client -> create_commit_checks client repo (S.Ref.of_string ref_) checks
        | _ -> Abb.Future.return (Ok ())

      let process_work_manifest t =
        let module Wm = Terrat_work_manifest2 in
        function
        | { Wm.run_type = Wm.Run_type.(Autoplan | Plan | Unsafe_apply); _ } as wm -> (
            let open Abbs_future_combinators.Infix_result_monad in
            maybe_require_index_work_manifest t wm
            >>= function
            | Some wm -> (
                maybe_update_commit_checks t wm
                >>= fun () ->
                let open Abb.Future.Infix_monad in
                S.Event.Initiate.of_work_manifest t wm
                >>= function
                | Ok _ as ret -> Abb.Future.return ret
                | Error (`Bad_glob_err (msg, _)) -> maybe_publish_msg t wm (Msg.Bad_glob msg)
                | Error `Error -> Abb.Future.return (Error `Error))
            | None ->
                let open Abb.Future.Infix_monad in
                S.Event.Initiate.done_ t wm >>= fun r -> Abb.Future.return (Ok r))
        | {
            Wm.run_type = Wm.Run_type.(Autoapply | Apply);
            src = Wm.Kind.Pull_request pr;
            changes;
            _;
          } as wm ->
            let open Abbs_future_combinators.Infix_result_monad in
            let change_dirspaces =
              CCList.map (fun { Terrat_change.Dirspaceflow.dirspace; _ } -> dirspace) changes
            in
            S.Event.Initiate.with_db t ~f:(fun db ->
                query_dirspaces_owned_by_other_pull_requests db pr change_dirspaces
                >>= function
                | [] -> (
                    query_dirspaces_without_valid_plans db pr change_dirspaces
                    >>= function
                    | [] -> (
                        let open Abbs_future_combinators.Infix_result_monad in
                        maybe_update_commit_checks t wm
                        >>= fun () ->
                        let open Abb.Future.Infix_monad in
                        S.Event.Initiate.of_work_manifest t wm
                        >>= function
                        | Ok _ as ret -> Abb.Future.return ret
                        | Error (`Bad_glob_err (msg, _)) ->
                            maybe_publish_msg t wm (Msg.Bad_glob msg)
                        | Error `Error -> Abb.Future.return (Error `Error))
                    | dirspaces -> maybe_publish_msg t wm (Msg.Missing_plans dirspaces))
                | dirspaces ->
                    maybe_publish_msg t wm (Msg.Dirspaces_owned_by_other_pull_request dirspaces))
        | { Wm.run_type = Wm.Run_type.(Autoapply | Apply); _ } as wm -> (
            let open Abbs_future_combinators.Infix_result_monad in
            (* TODO this might not be right *)
            maybe_update_commit_checks t wm
            >>= fun () ->
            let open Abb.Future.Infix_monad in
            S.Event.Initiate.of_work_manifest t wm
            >>= function
            | Ok _ as ret -> Abb.Future.return ret
            | Error (`Bad_glob_err (msg, _)) -> maybe_publish_msg t wm (Msg.Bad_glob msg)
            | Error `Error -> Abb.Future.return (Error `Error))

      let maybe_update_run_id db run_id =
        let open Abbs_future_combinators.Infix_result_monad in
        let module Wm = Terrat_work_manifest2 in
        function
        | { Wm.run_id = None; _ } as wm ->
            let wm = { wm with Wm.run_id = Some run_id } in
            update_work_manifest_run_id db wm >>= fun wm -> Abb.Future.return (Ok wm)
        | wm -> Abb.Future.return (Ok wm)

      let eval' t =
        let open Abbs_future_combinators.Infix_result_monad in
        let module Wm = Terrat_work_manifest2 in
        let work_manifest_id = S.Event.Initiate.work_manifest_id t in
        S.Event.Initiate.with_db t ~f:(fun db -> query_work_manifest db work_manifest_id)
        >>= function
        | Some ({ Wm.hash; _ } as wm)
          when CCString.equal hash (S.Ref.to_string (S.Event.Initiate.branch_ref t)) -> (
            log_work_manifest (S.Event.Initiate.request_id t) wm;
            S.Event.Initiate.with_db t ~f:(fun db ->
                maybe_update_run_id db (S.Event.Initiate.run_id t) wm)
            >>= fun wm ->
            match wm with
            | { Wm.state = Wm.State.Queued; _ } as wm ->
                let wm = { wm with Wm.state = Wm.State.Running } in
                S.Event.Initiate.with_db t ~f:(fun db -> update_work_manifest_state db wm)
                >>= fun wm -> process_work_manifest t wm
            | { Wm.state = Wm.State.Running; _ } as wm -> process_work_manifest t wm
            | { Wm.state = Wm.State.Completed; _ } as wm ->
                let open Abb.Future.Infix_monad in
                S.Event.Initiate.done_ t wm >>= fun r -> Abb.Future.return (Ok r)
            | { Wm.state = Wm.State.Aborted; _ } ->
                Abb.Future.return (Ok (S.Event.Initiate.work_manifest_not_found t)))
        | Some { Wm.hash; _ } ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : WORK_MANIFEST_REF_MISMATCH : id=%a : wm_ref=%s : ref=%s"
                  (S.Event.Initiate.request_id t)
                  Uuidm.pp
                  work_manifest_id
                  hash
                  (S.Ref.to_string (S.Event.Initiate.branch_ref t)));
            Abb.Future.return (Ok (S.Event.Initiate.work_manifest_not_found t))
        | None ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : WORK_MANIFEST_NOT_FOUND : id=%a"
                  (S.Event.Initiate.request_id t)
                  Uuidm.pp
                  work_manifest_id);
            Abb.Future.return (Ok (S.Event.Initiate.work_manifest_not_found t))

      let eval t =
        let open Abb.Future.Infix_monad in
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : EVAL : INITIATE : id=%a : branch_ref=%s : run_id=%s"
              (S.Event.Initiate.request_id t)
              Uuidm.pp
              (S.Event.Initiate.work_manifest_id t)
              (S.Ref.to_string (S.Event.Initiate.branch_ref t))
              (S.Event.Initiate.run_id t));
        eval' t
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "EVALUATOR : %s : DB : %a" (S.Event.Initiate.request_id t) Pgsql_pool.pp_err err);
            Abb.Future.return (Error `Error)
        | Error `Error -> Abb.Future.return (Error `Error)
        | Error (`Bad_glob err) ->
            Logs.info (fun m ->
                m "EVALUATOR : %s : BAD_GLOB : %s" (S.Event.Initiate.request_id t) err);
            Abb.Future.return (Error `Error)
        | Error (#Terrat_tag_query_ast.err as err) ->
            Logs.info (fun m ->
                m
                  "EVALUATOR : %s : TAG_QUERY : %a"
                  (S.Event.Initiate.request_id t)
                  Terrat_tag_query_ast.pp_err
                  err);
            Abb.Future.return (Error `Error)
    end

    module Unlock = struct
      let publish_msg t msg =
        Abbs_time_it.run
          (log_time (S.Event.Unlock.request_id t) "PUBLISH_MSG")
          (fun () -> S.Publish_msg.publish_msg (S.Event.Unlock.publish_msg t) msg)

      let eval' t =
        let open Abbs_future_combinators.Infix_result_monad in
        let client = S.Event.Unlock.client t in
        let repo = S.Event.Unlock.repo t in
        fetch_remote_repo client repo
        >>= fun remote_repo ->
        fetch_repo_config (S.Event.Unlock.client t) repo (S.Remote_repo.default_branch remote_repo)
        >>= fun repo_default_config ->
        let access_control =
          Access_control_engine.make
            ~request_id:(S.Event.Unlock.request_id t)
            ~ctx:(S.Event.Unlock.create_access_control_ctx t (S.Event.Unlock.client t))
            ~repo_config:repo_default_config
            ~user:(S.Event.Unlock.user t)
            ~policy_branch:(S.Remote_repo.default_branch remote_repo)
            ()
        in
        let open Abb.Future.Infix_monad in
        Access_control_engine.eval_pr_operation access_control `Unlock
        >>= function
        | Ok None ->
            Prmths.Counter.inc_one (Metrics.access_control_total ~t:"unlock" ~r:"allowed");
            let open Abbs_future_combinators.Infix_result_monad in
            Abbs_future_combinators.List_result.iter
              ~f:(S.Event.Unlock.unlock t)
              (S.Event.Unlock.ids t)
            >>= fun () ->
            publish_msg t Msg.Unlock_success
            >>= fun () -> Abb.Future.return (Ok (S.Event.Unlock.noop t))
        | Ok (Some match_list) ->
            let open Abbs_future_combinators.Infix_result_monad in
            Prmths.Counter.inc_one (Metrics.access_control_total ~t:"unlock" ~r:"denied");
            publish_msg
              t
              (Msg.Access_control_denied
                 (Access_control_engine.policy_branch access_control, `Unlock match_list))
            >>= fun () -> Abb.Future.return (Ok (S.Event.Unlock.noop t))
        | Error `Error ->
            let open Abbs_future_combinators.Infix_result_monad in
            Prmths.Counter.inc_one (Metrics.access_control_total ~t:"unlock" ~r:"denied");
            publish_msg
              t
              (Msg.Access_control_denied
                 (Access_control_engine.policy_branch access_control, `Lookup_err))
            >>= fun () -> Abb.Future.return (Error `Error)
        | Error (`Invalid_query query) ->
            let open Abbs_future_combinators.Infix_result_monad in
            Prmths.Counter.inc_one (Metrics.access_control_total ~t:"unlock" ~r:"denied");
            publish_msg
              t
              (Msg.Access_control_denied
                 ( Access_control_engine.policy_branch access_control,
                   `Terrateam_config_update_bad_query query ))
            >>= fun () -> Abb.Future.return (Error `Error)

      let eval t =
        let open Abb.Future.Infix_monad in
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : EVAL : UNLOCK : account=%s : repo=%s : user=%s"
              (S.Event.Unlock.request_id t)
              (S.Account.to_string (S.Event.Unlock.account t))
              (S.Repo.to_string (S.Event.Unlock.repo t))
              (S.Event.Unlock.user t));
        eval' t
        >>= function
        | Ok _ as ret -> Abb.Future.return ret
        | Error `Error -> Abb.Future.return (Error `Error)
    end

    module Push = struct
      let eval' t =
        let open Abbs_future_combinators.Infix_result_monad in
        S.Event.Push.update_drift_schedule t
        >>= fun () ->
        let drift = S.Event.Push.drift_of_t t in
        Drift.eval drift >>= fun _ -> Abb.Future.return (Ok ())

      let eval t =
        let open Abb.Future.Infix_monad in
        Logs.info (fun m ->
            m
              "EVALUATOR : %s : EVAL : PUSH : repo=%s : branch=%s"
              (S.Event.Push.request_id t)
              (S.Repo.to_string (S.Event.Push.repo t))
              (S.Ref.to_string (S.Event.Push.branch t)));
        eval' t
        >>= function
        | Ok _ -> Abb.Future.return (Ok (S.Event.Push.noop t))
        | Error `Error -> Abb.Future.return (Error `Error)
    end
  end

  module Runner = struct
    let next_work_manifest t =
      Abbs_time_it.run
        (fun time ->
          Logs.info (fun m ->
              m "EVALUATOR : %s : NEXT_WORK_MANIFEST : time=%f" (S.Runner.request_id t) time))
        (fun () -> S.Runner.next_work_manifest t)

    let run_work_manifest t client work_manifest =
      let module Wm = Terrat_work_manifest2 in
      Abbs_time_it.run
        (fun time ->
          Logs.info (fun m ->
              m
                "EVALUATOR : %s : RUN_WORK_MANIFEST : id=%a : time=%f"
                (S.Runner.request_id t)
                Uuidm.pp
                work_manifest.Wm.id
                time))
        (fun () -> S.Runner.run_work_manifest t client work_manifest)

    let get_repo =
      let module Wm = Terrat_work_manifest2 in
      function
      | { Wm.src = Wm.Kind.Pull_request pr; _ } -> S.Pull_request.repo pr
      | { Wm.src = Wm.Kind.Drift d; _ } -> S.Drift.repo d
      | { Wm.src = Wm.Kind.Index idx; _ } -> S.Index.repo idx

    let create_failed_commit_checks t client work_manifest =
      let module Wm = Terrat_work_manifest2 in
      match work_manifest.Wm.changes with
      | [] ->
          (* Don't create anything if no dirspaces exist *)
          Abb.Future.return (Ok ())
      | changes ->
          let module Status = Terrat_commit_check.Status in
          let repo = get_repo work_manifest in
          let unified_run_type =
            let module Urt = Terrat_work_manifest2.Unified_run_type in
            work_manifest.Wm.run_type |> Urt.of_run_type |> Urt.to_string
          in
          let aggregate =
            [
              S.make_commit_check
                ~description:"Failed"
                ~title:(Printf.sprintf "terrateam %s pre-hooks" unified_run_type)
                ~status:Status.Failed
                repo;
              S.make_commit_check
                ~description:"Failed"
                ~title:(Printf.sprintf "terrateam %s post-hooks" unified_run_type)
                ~status:Status.Failed
                repo;
            ]
          in
          let dirspace_checks =
            let module Ds = Terrat_change.Dirspace in
            let module Dsf = Terrat_change.Dirspaceflow in
            CCList.map
              (fun { Dsf.dirspace = { Ds.dir; workspace; _ }; _ } ->
                S.make_commit_check
                  ~description:"Failed"
                  ~title:(Printf.sprintf "terrateam %s: %s %s" unified_run_type dir workspace)
                  ~status:Status.Failed
                  repo)
              changes
          in
          let checks = aggregate @ dirspace_checks in
          create_commit_checks client repo (S.Ref.of_string work_manifest.Wm.hash) checks

    let create_commit_checks t client work_manifest =
      let module Wm = Terrat_work_manifest2 in
      match work_manifest.Wm.changes with
      | [] ->
          (* Don't create anything if no dirspaces exist *)
          Abb.Future.return (Ok ())
      | changes ->
          let module Status = Terrat_commit_check.Status in
          let repo = get_repo work_manifest in
          let unified_run_type =
            let module Urt = Terrat_work_manifest2.Unified_run_type in
            work_manifest.Wm.run_type |> Urt.of_run_type |> Urt.to_string
          in
          let aggregate =
            [
              S.make_commit_check
                ~description:"Running"
                ~title:(Printf.sprintf "terrateam %s pre-hooks" unified_run_type)
                ~status:Status.Queued
                repo;
              S.make_commit_check
                ~description:"Running"
                ~title:(Printf.sprintf "terrateam %s post-hooks" unified_run_type)
                ~status:Status.Queued
                repo;
            ]
          in
          let dirspace_checks =
            let module Ds = Terrat_change.Dirspace in
            let module Dsf = Terrat_change.Dirspaceflow in
            CCList.map
              (fun { Dsf.dirspace = { Ds.dir; workspace; _ }; _ } ->
                S.make_commit_check
                  ~description:"Running"
                  ~title:(Printf.sprintf "terrateam %s: %s %s" unified_run_type dir workspace)
                  ~status:Status.Queued
                  repo)
              changes
          in
          let checks = aggregate @ dirspace_checks in
          create_commit_checks client repo (S.Ref.of_string work_manifest.Wm.hash) checks

    let make_commit_checks =
      let module Wm = Terrat_work_manifest2 in
      function
      | { Wm.src = Wm.Kind.Pull_request _; _ } -> true
      | { Wm.src = Wm.Kind.(Drift _ | Index _); _ } -> false

    let rec eval' t =
      let open Abbs_future_combinators.Infix_result_monad in
      next_work_manifest t
      >>= function
      | Some work_manifest -> (
          S.Runner.client t work_manifest
          >>= fun client ->
          let open Abb.Future.Infix_monad in
          run_work_manifest t client work_manifest
          >>= function
          | Ok () when make_commit_checks work_manifest ->
              Abbs_future_combinators.ignore (create_commit_checks t client work_manifest)
              >>= fun () -> eval' t
          | Error `Error when make_commit_checks work_manifest ->
              Abbs_future_combinators.ignore (create_failed_commit_checks t client work_manifest)
              >>= fun () -> eval' t
          | Ok () | Error `Error -> eval' t)
      | None -> Abb.Future.return (Ok (S.Runner.completed t))

    let eval t =
      let open Abb.Future.Infix_monad in
      eval' t
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error `Error -> Abb.Future.return (Error `Error)
  end
end
