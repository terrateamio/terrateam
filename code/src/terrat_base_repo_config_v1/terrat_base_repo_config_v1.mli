module String_map = Terrat_data.String_map

module Pattern : sig
  type t [@@deriving show, yojson, eq]

  val make : string -> (t, [> `Pattern_parse_err of string ]) result
  val is_match : t -> string -> bool
  val pattern : t -> string
end

module Tag_query : sig
  type t = Terrat_tag_query.t [@@deriving show, yojson, eq]

  val any : t
end

module Workflow_step : sig
  (* Helper modules *)
  module Cmd : sig
    type t = string list [@@deriving show, yojson, eq]
  end

  module Run_on : sig
    type t =
      | Failure
      | Always
      | Success
    [@@deriving show, yojson, eq]
  end

  module Visible_on : sig
    type t =
      | Always
      | Failure
      | Success
    [@@deriving show, yojson, eq]

    val to_string : t -> string
  end

  module Retry : sig
    type t = {
      backoff : float; [@default 1.5]
      enabled : bool; [@default false]
      initial_sleep : int; [@default 5]
      tries : int; [@default 3]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Gate : sig
    type t = {
      any_of : string list option; [@default None]
      all_of : string list option; [@default None]
      any_of_count : int option; [@default None]
      token : string;
    }
    [@@deriving make, show, yojson, eq]
  end

  (* Workflow steps *)

  module Env : sig
    module Exec : sig
      type t = {
        cmd : Cmd.t;
        name : string;
        sensitive : bool; [@default false]
        trim_trailing_newlines : bool; [@default true]
      }
      [@@deriving make, show, yojson, eq]
    end

    module Source : sig
      type t = {
        cmd : Cmd.t;
        sensitive : bool; [@default false]
      }
      [@@deriving make, show, yojson, eq]
    end

    type t =
      | Exec of Exec.t
      | Source of Source.t
    [@@deriving show, yojson, eq]
  end

  module Oidc : sig
    module Aws : sig
      type t = {
        assume_role_arn : string option;
        assume_role_enabled : bool; [@default true]
        audience : string option;
        duration : int; [@default 3600]
        region : string; [@default "us-east-1"]
        role_arn : string;
        session_name : string; [@default "terrateam"]
      }
      [@@deriving make, show, yojson, eq]
    end

    module Gcp : sig
      type t = {
        access_token_lifetime : int; [@default 3600]
        access_token_subject : string option;
        audience : string option;
        project_id : string option;
        service_account : string;
        workload_identity_provider : string;
      }
      [@@deriving make, show, yojson, eq]
    end

    type t =
      | Aws of Aws.t
      | Gcp of Gcp.t
    [@@deriving show, yojson, eq]
  end

  module Run : sig
    type t = {
      capture_output : bool; [@default false]
      cmd : Cmd.t;
      env : string String_map.t option;
      ignore_errors : bool; [@default false]
      on_error : Yojson.Safe.t list; [@default []]
      run_on : Run_on.t; [@default Run_on.Success]
      visible_on : Visible_on.t; [@default Visible_on.Failure]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Init : sig
    type t = {
      env : string String_map.t option;
      extra_args : string list; [@default []]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Plan : sig
    module Mode : sig
      type t =
        | Strict
        | Fast_and_loose
      [@@deriving show, yojson, eq]
    end

    type t = {
      env : string String_map.t option;
      extra_args : string list; [@default []]
      mode : Mode.t; [@default Mode.Strict]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Apply : sig
    type t = {
      env : string String_map.t option;
      extra_args : string list; [@default []]
      retry : Retry.t option;
    }
    [@@deriving make, show, yojson, eq]
  end

  module Conftest : sig
    type t = {
      env : string String_map.t option;
      extra_args : string list; [@default []]
      gate : Gate.t option; [@default None]
      ignore_errors : bool; [@default false]
      run_on : Run_on.t; [@default Run_on.Success]
      visible_on : Visible_on.t; [@default Visible_on.Failure]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Checkov : sig
    type t = {
      env : string String_map.t option;
      extra_args : string list; [@default []]
      gate : Gate.t option; [@default None]
      ignore_errors : bool; [@default false]
      run_on : Run_on.t; [@default Run_on.Success]
      visible_on : Visible_on.t; [@default Visible_on.Failure]
    }
    [@@deriving make, show, yojson, eq]
  end
end

module Access_control : sig
  module Match : sig
    type t =
      | User of string
      | Team of string
      | Role of string
      | Any
    [@@deriving show, yojson, eq, ord]

    val make : string -> (t, [> `Match_parse_err of string ]) result
    val to_string : t -> string
  end

  module Match_list : sig
    type t = Match.t list [@@deriving show, yojson, eq]
  end

  module Policy : sig
    type t = {
      apply : Match_list.t; [@default [ Match.Any ]]
      apply_autoapprove : Match_list.t; [@default []]
      apply_force : Match_list.t; [@default []]
      apply_with_superapproval : Match_list.t; [@default []]
      plan : Match_list.t; [@default [ Match.Any ]]
      superapproval : Match_list.t; [@default []]
      tag_query : Tag_query.t;
    }
    [@@deriving make, show, yojson, eq]
  end

  module Policy_list : sig
    type t = Policy.t list [@@deriving show, yojson, eq]
  end

  type t = {
    apply_require_all_dirspace_access : bool; [@default true]
    ci_config_update : Match_list.t; [@default [ Match.Any ]]
    enabled : bool; [@default true]
    files : Match_list.t String_map.t; [@default String_map.empty]
    plan_require_all_dirspace_access : bool; [@default false]
    policies : Policy_list.t; [@default [ Policy.make ~tag_query:Terrat_tag_query.any () ]]
    terrateam_config_update : Match_list.t; [@default [ Match.Any ]]
    unlock : Match_list.t; [@default [ Match.Any ]]
  }
  [@@deriving make, show, yojson, eq]
end

module Apply_requirements : sig
  module Apply_after_merge : sig
    type t = { enabled : bool [@default false] } [@@deriving make, show, yojson, eq]
  end

  module Approved : sig
    type t = {
      all_of : Access_control.Match_list.t; [@default []]
      any_of : Access_control.Match_list.t; [@default []]
      any_of_count : int; [@default 1]
      enabled : bool; [@default true]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Merge_conflicts : sig
    type t = { enabled : bool [@default true] } [@@deriving make, show, yojson, eq]
  end

  module Status_checks : sig
    type t = {
      enabled : bool; [@default true]
      ignore_matching : string list; [@default []]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Check : sig
    type t = {
      apply_after_merge : Apply_after_merge.t; [@default Apply_after_merge.make ()]
      approved : Approved.t; [@default Approved.make ()]
      merge_conflicts : Merge_conflicts.t; [@default Merge_conflicts.make ()]
      require_ready_for_review_pr : bool; [@default true]
      status_checks : Status_checks.t; [@default Status_checks.make ()]
      tag_query : Tag_query.t; [@default Terrat_tag_query.any]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Check_list : sig
    type t = Check.t list [@@deriving show, yojson, eq]
  end

  type t = {
    checks : Check_list.t; [@default [ Check.make ~approved:(Approved.make ~enabled:false ()) () ]]
    create_pending_apply_check : bool; [@default true]
    create_completed_apply_check_on_noop : bool; [@default false]
  }
  [@@deriving make, show, yojson, eq]
end

module Automerge : sig
  type t = {
    delete_branch : bool; [@default false]
    enabled : bool; [@default false]
    require_explicit_apply : bool; [@default false]
  }
  [@@deriving make, show, yojson, eq]
end

module Batch_runs : sig
  type t = {
    enabled : bool; [@default false]
    max_workspaces_per_batch : int; [@default 1]
  }
  [@@deriving make, show, yojson, eq]
end

module Config_builder : sig
  type t = {
    enabled : bool; [@default false]
    script : string option;
  }
  [@@deriving make, show, yojson, eq]
end

module Cost_estimation : sig
  module Provider : sig
    type t = Infracost [@@deriving show, yojson, eq]
  end

  type t = {
    currency : string; [@default "USD"]
    enabled : bool; [@default true]
    provider : Provider.t; [@default Provider.Infracost]
  }
  [@@deriving make, show, yojson, eq]
end

module Destination_branches : sig
  module Destination_branch : sig
    type t = {
      branch : string;
      source_branches : string list; [@default [ "*" ]]
    }
    [@@deriving make, show, yojson, eq]
  end

  type t = Destination_branch.t list [@@deriving show, yojson, eq]
end

module File_pattern : sig
  type t [@@deriving show, yojson, eq]

  val make : string -> (t, [> `Glob_parse_err of string * string ]) result
  val is_match : t -> string -> bool
  val is_negate : t -> bool
  val file_pattern : t -> string
end

module File_pattern_list : sig
  type t = File_pattern.t list [@@deriving show, yojson, eq]
end

module When_modified : sig
  type t = {
    autoapply : bool; [@default false]
    autoplan : bool; [@default false]
    autoplan_draft_pr : bool; [@default true]
    depends_on : Tag_query.t option;
    file_patterns : File_pattern_list.t;
        [@default
          [
            CCResult.get_exn (File_pattern.make "**/*.tf");
            CCResult.get_exn (File_pattern.make "**/*.tfvars");
          ]]
  }
  [@@deriving make, show, yojson, eq]
end

module Dirs : sig
  module Workspace : sig
    type t = {
      tags : string list; [@default []]
      when_modified : When_modified.t; [@default When_modified.make ()]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Dir : sig
    module Branch_target : sig
      type t =
        | All
        | Dest_branch
      [@@deriving show, yojson, eq]
    end

    type t = {
      create_and_select_workspace : bool; [@default true]
      lock_branch_target : Branch_target.t; [@default Branch_target.All]
      stacks : Workspace.t String_map.t; [@default String_map.empty]
      tags : string list; [@default []]
      workspaces : Workspace.t String_map.t;
          [@default String_map.of_list [ ("default", Workspace.make ()) ]]
    }
    [@@deriving make, show, yojson, eq]
  end

  type t = Dir.t String_map.t [@@deriving show, yojson, eq]
end

module Drift : sig
  module Window : sig
    type t = {
      end_ : string;
      start : string;
    }
    [@@deriving show, yojson, eq]

    val make :
      start:string -> end_:string -> unit -> (t, [> `Window_parse_timezone_err of string ]) result
  end

  module Schedule : sig
    module Sched : sig
      type t =
        | Hourly
        | Daily
        | Weekly
        | Monthly
      [@@deriving show, yojson, eq]

      val to_string : t -> string
    end

    type t = {
      tag_query : Tag_query.t;
      schedule : Sched.t;
      reconcile : bool; [@default false]
      window : Window.t option;
    }
    [@@deriving make, show, yojson, eq]
  end

  type t = {
    enabled : bool; [@default false]
    schedules : Schedule.t String_map.t; [@default String_map.empty]
  }
  [@@deriving make, show, yojson, eq]
end

module Engine : sig
  module Cdktf : sig
    type t = {
      override_tf_cmd : string option;
      tf_cmd : string; [@default "terraform"]
      tf_version : string; [@default "latest"]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Custom : sig
    type t = {
      apply : string list option;
      diff : string list option;
      init : string list option;
      outputs : string list option;
      plan : string list option;
      unsafe_apply : string list option;
    }
    [@@deriving make, show, yojson, eq]
  end

  module Fly : sig
    type t = { config_file : string } [@@deriving make, show, yojson, eq]
  end

  module Opentofu : sig
    type t = {
      override_tf_cmd : string option;
      version : string option;
    }
    [@@deriving make, show, yojson, eq]
  end

  module Terraform : sig
    type t = {
      override_tf_cmd : string option;
      version : string option;
    }
    [@@deriving make, show, yojson, eq]
  end

  module Terragrunt : sig
    type t = {
      override_tf_cmd : string option;
      tf_cmd : string; [@default "terraform"]
      tf_version : string option;
      version : string option;
    }
    [@@deriving make, show, yojson, eq]
  end

  type t =
    | Cdktf of Cdktf.t
    | Custom of Custom.t
    | Fly of Fly.t
    | Opentofu of Opentofu.t
    | Other of Yojson.Safe.t
    | Pulumi
    | Terraform of Terraform.t
    | Terragrunt of Terragrunt.t
  [@@deriving show, yojson, eq]
end

module Hooks : sig
  module Hook_op : sig
    type t =
      | Drift_create_issue
      | Env of Workflow_step.Env.t
      | Oidc of Workflow_step.Oidc.t
      | Run of Workflow_step.Run.t
    [@@deriving show, yojson, eq]
  end

  module Hook_op_list : sig
    type t = Hook_op.t list [@@deriving show, yojson, eq]
  end

  module Hook : sig
    type t = {
      pre : Hook_op_list.t; [@default []]
      post : Hook_op_list.t; [@default []]
    }
    [@@deriving make, show, yojson, eq]
  end

  type t = {
    all : Hook.t; [@default Hook.make ()]
    apply : Hook.t; [@default Hook.make ()]
    plan : Hook.t; [@default Hook.make ()]
  }
  [@@deriving make, show, yojson, eq]
end

module Indexer : sig
  type t = {
    build_tag : string option;
    enabled : bool; [@default false]
  }
  [@@deriving make, show, yojson, eq]
end

module Integrations : sig
  module Resourcely : sig
    type t = {
      enabled : bool; [@default false]
      extra_args : string list; [@default []]
    }
    [@@deriving make, show, yojson, eq]
  end

  type t = { resourcely : Resourcely.t [@default Resourcely.make ()] }
  [@@deriving make, show, yojson, eq]
end

module Notifications : sig
  module Policy : sig
    module Strategy : sig
      type t =
        | Append
        | Delete
        | Minimize
      [@@deriving show, yojson, eq]
    end

    type t = {
      tag_query : Tag_query.t;
      comment_strategy : Strategy.t; [@default Strategy.Append]
    }
    [@@deriving make, show, yojson, eq]
  end

  type t = { policies : Policy.t list [@default [ Policy.make ~tag_query:Tag_query.any () ]] }
  [@@deriving make, show, yojson, eq]
end

module Storage : sig
  module Plans : sig
    module Cmd : sig
      type t = {
        delete : Workflow_step.Cmd.t option;
        fetch : Workflow_step.Cmd.t;
        store : Workflow_step.Cmd.t;
      }
      [@@deriving make, show, yojson, eq]
    end

    module S3 : sig
      type t = {
        access_key_id : string option;
        bucket : string;
        delete_extra_args : string list; [@default []]
        delete_used_plans : bool; [@default true]
        fetch_extra_args : string list; [@default []]
        path : string option;
        region : string;
        secret_access_key : string option;
        store_extra_args : string list; [@default []]
      }
      [@@deriving make, show, yojson, eq]
    end

    type t =
      | Terrateam
      | Cmd of Cmd.t
      | S3 of S3.t
    [@@deriving show, yojson, eq]
  end

  type t = { plans : Plans.t [@default Plans.Terrateam] } [@@deriving make, show, yojson, eq]
end

module Tags : sig
  module Branch : sig
    type t = Pattern.t String_map.t [@@deriving show, yojson, eq]
  end

  type t = {
    branch : Branch.t; [@default String_map.empty]
    dest_branch : Branch.t; [@default String_map.empty]
  }
  [@@deriving make, show, yojson, eq]
end

module Tree_builder : sig
  type t = {
    enabled : bool; [@default false]
    script : string; [@default ""]
  }
  [@@deriving make, show, yojson, eq]
end

module Workflows : sig
  module Entry : sig
    module Op : sig
      type t =
        | Init of Workflow_step.Init.t
        | Plan of Workflow_step.Plan.t
        | Apply of Workflow_step.Apply.t
        | Run of Workflow_step.Run.t
        | Env of Workflow_step.Env.t
        | Oidc of Workflow_step.Oidc.t
        | Checkov of Workflow_step.Checkov.t
        | Conftest of Workflow_step.Conftest.t
      [@@deriving show, yojson, eq]
    end

    module Op_list : sig
      type t = Op.t list [@@deriving show, yojson, eq]
    end

    module Lock_policy : sig
      type t =
        | Apply
        | Merge
        | None
        | Strict
      [@@deriving show, yojson, eq]
    end

    type t = {
      apply : Op_list.t;
          [@default
            [ Op.Init (Workflow_step.Init.make ()); Op.Apply (Workflow_step.Apply.make ()) ]]
      engine : Engine.t; [@default Engine.(Terraform (Terraform.make ()))]
      environment : string option;
      integrations : Integrations.t; [@default Integrations.make ()]
      lock_policy : Lock_policy.t; [@default Lock_policy.Strict]
      plan : Op_list.t;
          [@default [ Op.Init (Workflow_step.Init.make ()); Op.Plan (Workflow_step.Plan.make ()) ]]
      runs_on : Yojson.Safe.t option; [@default None]
      tag_query : Tag_query.t;
    }
    [@@deriving make, show, yojson, eq]
  end

  type t = Entry.t list [@@deriving show, yojson, eq]
end

module View : sig
  type t = {
    access_control : Access_control.t; [@default Access_control.make ()]
    apply_requirements : Apply_requirements.t; [@default Apply_requirements.make ()]
    automerge : Automerge.t; [@default Automerge.make ()]
    batch_runs : Batch_runs.t; [@default Batch_runs.make ()]
    config_builder : Config_builder.t; [@default Config_builder.make ()]
    cost_estimation : Cost_estimation.t; [@default Cost_estimation.make ()]
    create_and_select_workspace : bool; [@default true]
    destination_branches : Destination_branches.t; [@default []]
    dirs : Dirs.t; [@default String_map.empty]
    drift : Drift.t; [@default Drift.make ()]
    enabled : bool; [@default true]
    engine : Engine.t; [@default Engine.(Terraform (Terraform.make ()))]
    hooks : Hooks.t; [@default Hooks.make ()]
    indexer : Indexer.t; [@default Indexer.make ()]
    integrations : Integrations.t; [@default Integrations.make ()]
    notifications: Notifications.t; [@default Notifications.make ()]
    parallel_runs : int; [@default 3]
    storage : Storage.t; [@default Storage.make ()]
    tags : Tags.t; [@default Tags.make ()]
    tree_builder : Tree_builder.t; [@default Tree_builder.make ()]
    when_modified : When_modified.t; [@default When_modified.make ()]
    workflows : Workflows.t; [@default []]
  }
  [@@deriving make, show, yojson, eq]
end

module Ctx : sig
  type t = {
    dest_branch : string;
    branch : string;
  }

  val make : dest_branch:string -> branch:string -> unit -> t
end

module Index : sig
  module Dep : sig
    type t = Module of string
  end

  type t = {
    deps : Dep.t list String_map.t;
    symlinks : (string * string) list;
  }

  val empty : t
  val make : symlinks:(string * string) list -> (string * Dep.t list) list -> t
end

type raw
type derived
type 'a t

type of_version_1_err =
  [ `Access_control_ci_config_update_match_parse_err of string
  | `Access_control_file_match_parse_err of string * string
  | `Access_control_policy_apply_autoapprove_match_parse_err of string
  | `Access_control_policy_apply_force_match_parse_err of string
  | `Access_control_policy_apply_match_parse_err of string
  | `Access_control_policy_apply_with_superapproval_match_parse_err of string
  | `Access_control_policy_plan_match_parse_err of string
  | `Access_control_policy_superapproval_match_parse_err of string
  | `Access_control_policy_tag_query_err of string * string
  | `Access_control_terrateam_config_update_match_parse_err of string
  | `Access_control_unlock_match_parse_err of string
  | `Apply_requirements_approved_all_of_match_parse_err of string
  | `Apply_requirements_approved_any_of_match_parse_err of string
  | `Apply_requirements_check_tag_query_err of string * string
  | `Depends_on_err of string * string
  | `Drift_schedule_err of string
  | `Drift_tag_query_err of string * string
  | `Glob_parse_err of string * string
  | `Hooks_unknown_run_on_err of Terrat_repo_config_run_on.t
  | `Hooks_unknown_visible_on_err of string
  | `Notification_policy_comment_strategy_err of string
  | `Notification_policy_tag_query_err of string * string
  | `Pattern_parse_err of string
  | `Unknown_lock_policy_err of string
  | `Unknown_plan_mode_err of string
  | `Window_parse_timezone_err of string
  | `Workflows_apply_unknown_run_on_err of Terrat_repo_config_run_on.t
  | `Workflows_apply_unknown_visible_on_err of string
  | `Workflows_plan_unknown_run_on_err of Terrat_repo_config_run_on.t
  | `Workflows_plan_unknown_visible_on_err of string
  | `Workflows_tag_query_parse_err of string * string
  ]
[@@deriving show]

type of_version_1_json_err =
  [ of_version_1_err
  | `Repo_config_schema_err of Jsonschema_check.Validation_err.t list
  ]
[@@deriving show]

val of_view : View.t -> raw t
val to_view : 'a t -> View.t
val default : raw t
val of_version_1 : Terrat_repo_config.Version_1.t -> (raw t, [> of_version_1_err ]) result
val of_version_1_json : Yojson.Safe.t -> (raw t, [> of_version_1_json_err ]) result
val to_version_1 : 'a t -> Terrat_repo_config.Version_1.t
val merge_with_default_branch_config : default:'a t -> 'a t -> 'a t

(** Given contextual information, take a configuration and produce a derived configuration. *)
val derive : ctx:Ctx.t -> index:Index.t -> file_list:string list -> 'a t -> derived t

(** Accessors*)

val access_control : 'a t -> Access_control.t
val apply_requirements : 'a t -> Apply_requirements.t
val automerge : 'a t -> Automerge.t
val batch_runs : 'a t -> Batch_runs.t
val config_builder : 'a t -> Config_builder.t
val cost_estimation : 'a t -> Cost_estimation.t
val create_and_select_workspace : 'a t -> bool
val destination_branches : 'a t -> Destination_branches.t
val dirs : 'a t -> Dirs.t
val drift : 'a t -> Drift.t
val enabled : 'a t -> bool
val engine : 'a t -> Engine.t
val hooks : 'a t -> Hooks.t
val indexer : 'a t -> Indexer.t
val integrations : 'a t -> Integrations.t
val parallel_runs : 'a t -> int
val storage : 'a t -> Storage.t
val tags : 'a t -> Tags.t
val tree_builder : 'a t -> Tree_builder.t
val when_modified : 'a t -> When_modified.t
val workflows : 'a t -> Workflows.t
