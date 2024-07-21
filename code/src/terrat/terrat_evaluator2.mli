module Unlock_id : sig
  type t =
    | Pull_request of int
    | Drift
  [@@deriving show]
end

module Msg : sig
  type access_control_denied =
    [ `All_dirspaces of Terrat_access_control.R.Deny.t list
    | `Dirspaces of Terrat_access_control.R.Deny.t list
    | `Lookup_err
    | `Terrateam_config_update of Terrat_base_repo_config_v1.Access_control.Match_list.t
    | `Unlock of Terrat_base_repo_config_v1.Access_control.Match_list.t
    ]

  type ('pull_request, 'src, 'apply_requirements) t =
    | Access_control_denied of (string * access_control_denied)
    | Account_expired
    | Apply_no_matching_dirspaces
    | Apply_requirements_config_err of [ Terrat_tag_query_ast.err | `Invalid_query of string ]
    | Apply_requirements_validation_err
    | Autoapply_running
    | Bad_custom_branch_tag_pattern of (string * string)
    | Bad_glob of string
    | Conflicting_work_manifests of 'src Terrat_work_manifest2.Existing.t list
    | Depends_on_cycle of Terrat_dirspace.t list
    | Dest_branch_no_match of 'pull_request
    | Dirspaces_owned_by_other_pull_request of (Terrat_change.Dirspace.t * 'pull_request) list
    | Index_complete of (bool * (string * int option * string) list)
    | Maybe_stale_work_manifests of 'src Terrat_work_manifest2.Existing.t list
    | Mismatched_refs
    | Missing_plans of Terrat_change.Dirspace.t list
    | Plan_no_matching_dirspaces
    | Pull_request_not_appliable of ('pull_request * 'apply_requirements)
    | Pull_request_not_mergeable
    | Repo_config of (string list * Terrat_base_repo_config_v1.t * Terrat_change_match2.Config.t)
    | Repo_config_err of Terrat_base_repo_config_v1.of_version_1_err
    | Repo_config_failure of string
    | Repo_config_parse_failure of string * string
    | Tag_query_err of Terrat_tag_query_ast.err
    | Unexpected_temporary_err
    | Unlock_success
end

module Conflicting_work_manifests : sig
  type 'a t =
    | Conflicting of 'a list
    | Maybe_stale of 'a list
end

module Tf_operation : sig
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

  val to_run_type : t -> Terrat_work_manifest2.Run_type.t
  val of_run_type : Terrat_work_manifest2.Run_type.t -> t
end

module Result_status : sig
  type t = {
    dirspaces : (Terrat_change.Dirspace.t * bool) list;
    overall : bool;
    post_hooks : bool;
    pre_hooks : bool;
  }
  [@@deriving show]
end

type fetch_repo_config_err =
  [ Terrat_base_repo_config_v1.of_version_1_err
  | `Repo_config_parse_err of string * string
  | Terrat_json.merge_err
  | `Json_decode_err of string * string
  | `Unexpected_err of string
  | `Yaml_decode_err of string * string
  | `Error
  ]
[@@deriving show]

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

    val owner : t -> string
    val name : t -> string
    val to_string : t -> string
  end

  module Remote_repo : sig
    type t

    val to_repo : t -> Repo.t
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

    (** The branch ref based on if the PR is merged or not. *)
    val working_branch_ref : 'a t -> Ref.t

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

  val fetch_centralized_repo :
    Client.t -> string -> (Remote_repo.t option, [> `Error ]) result Abb.Future.t

  val fetch_remote_repo : Client.t -> Repo.t -> (Remote_repo.t, [> `Error ]) result Abb.Future.t
  val fetch_tree : Client.t -> Repo.t -> Ref.t -> (string list, [> `Error ]) result Abb.Future.t

  val fetch_branch_sha :
    Client.t -> Repo.t -> Ref.t -> (Ref.t option, [> `Error ]) result Abb.Future.t

  val fetch_file :
    Client.t -> Repo.t -> Ref.t -> string -> (string option, [> `Error ]) result Abb.Future.t

  val query_index :
    Db.t ->
    Account.t ->
    Ref.t ->
    (Terrat_change_match2.Index.t option, [> `Error ]) result Abb.Future.t

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
      Conflicting_work_manifests.t
      option,
      [> `Error ] )
    result
    Abb.Future.t

  val query_unapplied_dirspaces :
    Db.t -> 'a Pull_request.t -> (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_applied_dirspaces :
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
    ?work_manifest:'a Terrat_work_manifest2.Existing.t ->
    config:Terrat_config.t ->
    description:string ->
    title:string ->
    status:Terrat_commit_check.Status.t ->
    Account.t ->
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

      val created_work_manifests :
        t ->
        (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
        Terrat_work_manifest2.Existing.t
        list ->
        r

      val with_db :
        t ->
        f:(Db.t -> ('a, ([> Pgsql_pool.err ] as 'e)) result Abb.Future.t) ->
        ('a, 'e) result Abb.Future.t

      val check_apply_requirements :
        t ->
        Client.t ->
        Pull_request.fetched Pull_request.t ->
        Terrat_base_repo_config_v1.t ->
        Terrat_change_match2.Dirspace_config.t list ->
        ( Apply_requirements.t,
          [> `Error | `Invalid_query of string | Terrat_tag_query_ast.err ] )
        result
        Abb.Future.t
    end

    module Initiate : sig
      type t
      type r

      (* Responses *)
      val of_work_manifest :
        t ->
        (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
        Terrat_work_manifest2.Existing.t ->
        (Client.t ->
        Repo.t ->
        Ref.t ->
        (Terrat_base_repo_config_v1.t, fetch_repo_config_err) result Abb.Future.t) ->
        (r, [> `Error | `Bad_glob_err of string * string | fetch_repo_config_err ]) result
        Abb.Future.t

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
        t ->
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
        bool ->
        Terrat_change_match2.Dirspace_config.t list list ->
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
        val tag_query : t -> Terrat_tag_query.t
      end

      module Data : sig
        type t

        val branch_name : t -> Ref.t
        val branch_ref : t -> Ref.t
        val index : t -> Terrat_change_match2.Index.t option
        val repo_config : t -> Terrat_base_repo_config_v1.t
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

      val fetch_data :
        t ->
        Schedule.t ->
        (Client.t ->
        Repo.t ->
        Ref.t ->
        (Terrat_base_repo_config_v1.t, fetch_repo_config_err) result Abb.Future.t) ->
        (Data.t, [> `Error | fetch_repo_config_err ]) result Abb.Future.t
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

      val update_drift_schedule :
        t ->
        (Client.t ->
        Repo.t ->
        Ref.t ->
        (Terrat_base_repo_config_v1.t, fetch_repo_config_err) result Abb.Future.t) ->
        (unit, [> `Error | fetch_repo_config_err ]) result Abb.Future.t

      val drift_of_t : t -> Drift.t
      val repo : t -> Repo.t
      val request_id : t -> string
      val branch : t -> Ref.t
    end
  end

  module Runner : sig
    type t
    type r

    val config : t -> Terrat_config.t
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

module Make (S : S) : sig
  module Event : sig
    module Drift : sig
      val eval : S.Event.Drift.t -> (S.Event.Drift.r, [> `Error ]) result Abb.Future.t
    end

    module Index : sig
      val eval : S.Event.Index.t -> (S.Event.Index.r, [> `Error ]) result Abb.Future.t
    end

    module Initiate : sig
      val eval : S.Event.Initiate.t -> (S.Event.Initiate.r, [> `Error ]) result Abb.Future.t
    end

    module Plan_cleanup : sig
      val eval : S.Event.Plan_cleanup.t -> (S.Event.Plan_cleanup.r, [> `Error ]) result Abb.Future.t
    end

    module Plan_get : sig
      val eval : S.Event.Plan_get.t -> (S.Event.Plan_get.r, [> `Error ]) result Abb.Future.t
    end

    module Plan_set : sig
      val eval : S.Event.Plan_set.t -> (S.Event.Plan_set.r, [> `Error ]) result Abb.Future.t
    end

    module Result : sig
      val eval : S.Event.Result.t -> (S.Event.Result.r, [> `Error ]) result Abb.Future.t
    end

    module Repo_config : sig
      val eval : S.Event.Repo_config.t -> (S.Event.Repo_config.r, [> `Error ]) result Abb.Future.t
    end

    module Terraform : sig
      val eval : S.Event.Terraform.t -> (S.Event.Terraform.r, [> `Error ]) result Abb.Future.t
    end

    module Unlock : sig
      val eval : S.Event.Unlock.t -> (S.Event.Unlock.r, [> `Error ]) result Abb.Future.t
    end

    module Push : sig
      val eval : S.Event.Push.t -> (S.Event.Push.r, [> `Error ]) result Abb.Future.t
    end
  end

  module Runner : sig
    val eval : S.Runner.t -> (S.Runner.r, [> `Error ]) result Abb.Future.t
  end
end
