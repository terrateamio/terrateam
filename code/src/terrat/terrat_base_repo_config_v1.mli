module String_map : sig
  include module type of CCMap.Make (CCString)

  val to_yojson : ('a -> 'b) -> 'a t -> [> `Assoc of (key * 'b) list ]

  val of_yojson :
    ('a -> ('b, string) result) -> [> `Assoc of (key * 'a) list ] -> ('b t, string) result

  val pp : (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a t -> unit
  val show : (Format.formatter -> 'a -> unit) -> 'a t -> string
end

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

  module Retry : sig
    type t = {
      backoff : float; [@default 1.5]
      enabled : bool; [@default false]
      initial_sleep : int; [@default 5]
      tries : int; [@default 3]
    }
    [@@deriving make, show, yojson, eq]
  end

  (* Workflow steps *)

  module Env : sig
    module Exec : sig
      type t = {
        cmd : Cmd.t;
        name : string;
        trim_trailing_newlines : bool; [@default true]
      }
      [@@deriving make, show, yojson, eq]
    end

    module Source : sig
      type t = { cmd : Cmd.t } [@@deriving make, show, yojson, eq]
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
      run_on : Run_on.t; [@default Run_on.Success]
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
    type t = {
      env : string String_map.t option;
      extra_args : string list; [@default []]
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
end

module Access_control : sig
  module Match : sig
    type t =
      | User of string
      | Team of string
      | Repo of string
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
    enabled : bool; [@default true]
    plan_require_all_dirspace_access : bool; [@default false]
    policies : Policy_list.t; [@default [ Policy.make ~tag_query:Terrat_tag_query.any () ]]
    terrateam_config_update : Match_list.t; [@default [ Match.Any ]]
    unlock : Match_list.t; [@default [ Match.Any ]]
  }
  [@@deriving make, show, yojson, eq]
end

module Apply_requirements : sig
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
      approved : Approved.t; [@default Approved.make ()]
      merge_conflicts : Merge_conflicts.t; [@default Merge_conflicts.make ()]
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
  }
  [@@deriving make, show, yojson, eq]
end

module Automerge : sig
  type t = {
    delete_branch : bool; [@default false]
    enabled : bool; [@default false]
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
    type t = { tags : string list [@default []] } [@@deriving make, show, yojson, eq]
  end

  module Dir : sig
    type t = {
      create_and_select_workspace : bool; [@default true]
      stacks : Workspace.t String_map.t; [@default String_map.empty]
      tags : string list; [@default []]
      when_modified : When_modified.t; [@default When_modified.make ()]
      workspaces : Workspace.t String_map.t; [@default String_map.empty]
    }
    [@@deriving make, show, yojson, eq]
  end

  type t = Dir.t String_map.t [@@deriving show, yojson, eq]
end

module Drift : sig
  module Schedule : sig
    type t =
      | Hourly
      | Daily
      | Weekly
      | Monthly
    [@@deriving show, yojson, eq]

    val to_string : t -> string
  end

  type t = {
    enabled : bool; [@default false]
    reconcile : bool; [@default false]
    schedule : Schedule.t; [@default Schedule.Weekly]
    tag_query : Tag_query.t; [@default Tag_query.any]
  }
  [@@deriving make, show, yojson, eq]
end

module Engine : sig
  module Cdktf : sig
    type t = {
      tf_cmd : string; [@default "terraform"]
      tf_version : string; [@default "latest"]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Opentofu : sig
    type t = { version : string [@default "latest"] } [@@deriving make, show, yojson, eq]
  end

  module Terraform : sig
    type t = { version : string [@default "latest"] } [@@deriving make, show, yojson, eq]
  end

  module Terragrunt : sig
    type t = {
      tf_cmd : string; [@default "terraform"]
      tf_version : string; [@default "latest"]
      version : string; [@default "latest"]
    }
    [@@deriving make, show, yojson, eq]
  end

  type t =
    | Cdktf of Cdktf.t
    | Opentofu of Opentofu.t
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
      apply : Op_list.t; [@default []]
      engine : Engine.t; [@default Engine.(Terraform (Terraform.make ()))]
      environment : string option;
      integrations : Integrations.t; [@default Integrations.make ()]
      lock_policy : Lock_policy.t; [@default Lock_policy.Strict]
      plan : Op_list.t; [@default []]
      tag_query : Tag_query.t;
    }
    [@@deriving make, show, yojson, eq]
  end

  type t = Entry.t list [@@deriving show, yojson, eq]
end

type t = {
  access_control : Access_control.t; [@default Access_control.make ()]
  apply_requirements : Apply_requirements.t; [@default Apply_requirements.make ()]
  automerge : Automerge.t; [@default Automerge.make ()]
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
  parallel_runs : int; [@default 3]
  storage : Storage.t; [@default Storage.make ()]
  tags : Tags.t; [@default Tags.make ()]
  when_modified : When_modified.t; [@default When_modified.make ()]
  workflows : Workflows.t; [@default []]
}
[@@deriving make, show, yojson, eq]

type of_version_1_err =
  [ `Access_control_policy_apply_autoapprove_match_parse_err of string
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
  | `Drift_schedule_err of string
  | `Drift_tag_query_err of string * string
  | `Glob_parse_err of string * string
  | `Hooks_unknown_run_on_err of Terrat_repo_config_run_on.t
  | `Pattern_parse_err of string
  | `Unknown_lock_policy_err of string
  | `Workflows_apply_unknown_run_on_err of Terrat_repo_config_run_on.t
  | `Workflows_plan_unknown_run_on_err of Terrat_repo_config_run_on.t
  | `Workflows_tag_query_parse_err of string * string
  ]
[@@deriving show]

val of_version_1 : Terrat_repo_config.Version_1.t -> (t, [> of_version_1_err ]) result
val to_version_1 : t -> Terrat_repo_config.Version_1.t
val merge_with_default_branch_config : default:t -> t -> t
