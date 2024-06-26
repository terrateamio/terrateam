module V1 = Terrat_repo_config.Version_1

module Assoc_string_list = struct
  type 'a t = (string * 'a) list [@@deriving show]
end

module String_map = struct
  include CCMap.Make (CCString)

  let to_yojson f t = `Assoc (CCList.map (fun (k, v) -> (k, f v)) (to_list t))

  let of_yojson f = function
    | `Assoc obj -> (
        try
          Ok
            (CCListLabels.fold_left
               ~f:(fun acc (k, v) ->
                 match f v with
                 | Ok v -> add k v acc
                 | Error err -> failwith err)
               ~init:empty
               obj)
        with Failure err -> Error err)
    | _ -> Error "Expected object"

  let pp f formatter t = Assoc_string_list.pp f formatter (to_list t)
  let show f t = Assoc_string_list.show f (to_list t)
end

let map_opt f = function
  | None -> Ok None
  | Some v ->
      let open CCResult.Infix in
      f v >>= fun v -> Ok (Some v)

let map_opt_if_true test f v = if test v then Some (f v) else None

module Pattern = struct
  type t = {
    s : string;
    p : Lua_pattern.t;
  }

  let make s =
    match Lua_pattern.of_string s with
    | Some p -> Ok { s; p }
    | None -> Error (`Pattern_parse_err s)

  let is_match { p; _ } str = CCOption.is_some (Lua_pattern.find str p)
  let pattern { s; _ } = s
  let equal p1 p2 = CCString.equal (pattern p1) (pattern p2)
  let pp formatter { s; _ } = Format.fprintf formatter "%s" s
  let show { s; _ } = s
  let to_string { s; _ } = s
  let to_yojson { s; _ } = `String s

  let of_yojson = function
    | `String s -> CCResult.map_err (fun _ -> "Pattern_parse_err " ^ s) (make s)
    | _ -> Error "Expected string"
end

module Tag_query = struct
  type t = Terrat_tag_query.t [@@deriving eq]

  let any = Terrat_tag_query.any
  let to_yojson t = `String (Terrat_tag_query.to_string t)

  let of_yojson = function
    | `String s -> (
        match Terrat_tag_query.of_string s with
        | Ok t -> Ok t
        | Error (`Tag_query_error (_query, err)) -> Error err)
    | _ -> Error "Expected string"

  let pp formatter t = Format.fprintf formatter "%s" (Terrat_tag_query.to_string t)
  let show = Terrat_tag_query.to_string
end

module Workflow_step = struct
  (* Helper modules *)
  module Cmd = struct
    type t = string list [@@deriving show, yojson, eq]
  end

  module Run_on = struct
    type t =
      | Failure
      | Always
      | Success
    [@@deriving show, yojson, eq]

    let to_string = function
      | Failure -> "failure"
      | Always -> "always"
      | Success -> "success"
  end

  module Retry = struct
    type t = {
      backoff : float; [@default 1.5]
      enabled : bool; [@default false]
      initial_sleep : int; [@default 5]
      tries : int; [@default 3]
    }
    [@@deriving make, show, yojson, eq]
  end

  (* Workflow steps *)
  module Env = struct
    module Exec = struct
      type t = {
        cmd : Cmd.t;
        name : string;
        trim_trailing_newlines : bool; [@default true]
      }
      [@@deriving make, show, yojson, eq]
    end

    module Source = struct
      type t = { cmd : Cmd.t } [@@deriving make, show, yojson, eq]
    end

    type t =
      | Exec of Exec.t
      | Source of Source.t
    [@@deriving show, yojson, eq]
  end

  module Oidc = struct
    module Aws = struct
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

    module Gcp = struct
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

  module Run = struct
    type t = {
      capture_output : bool; [@default false]
      cmd : Cmd.t;
      env : string String_map.t option;
      run_on : Run_on.t; [@default Run_on.Success]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Init = struct
    type t = {
      env : string String_map.t option;
      extra_args : string list; [@default []]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Plan = struct
    module Mode = struct
      type t =
        | Strict
        | Fast_and_loose
      [@@deriving show, yojson, eq]

      let to_string = function
        | Strict -> "strict"
        | Fast_and_loose -> "fast-and-loose"
    end

    type t = {
      env : string String_map.t option;
      extra_args : string list; [@default []]
      mode : Mode.t; [@default Mode.Strict]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Apply = struct
    type t = {
      env : string String_map.t option;
      extra_args : string list; [@default []]
      retry : Retry.t option;
    }
    [@@deriving make, show, yojson, eq]
  end
end

module Access_control = struct
  module Match = struct
    type t =
      | User of string
      | Team of string
      | Repo of string
      | Any
    [@@deriving show, yojson, eq, ord]

    let make m =
      match CCString.Split.left ~by:":" m with
      | Some ("user", user) -> Ok (User user)
      | Some ("team", team) -> Ok (Team team)
      | Some ("repo", repo) -> Ok (Repo repo)
      | _ when CCString.equal m "*" -> Ok Any
      | _ -> Error (`Match_parse_err m)

    let to_string = function
      | User user -> "user:" ^ user
      | Team team -> "team:" ^ team
      | Repo repo -> "repo:" ^ repo
      | Any -> "*"
  end

  module Match_list = struct
    type t = Match.t list [@@deriving show, yojson, eq]
  end

  module Policy = struct
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

  module Policy_list = struct
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

module Apply_requirements = struct
  module Approved = struct
    type t = {
      all_of : Access_control.Match_list.t; [@default []]
      any_of : Access_control.Match_list.t; [@default []]
      any_of_count : int; [@default 1]
      enabled : bool; [@default false]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Merge_conflicts = struct
    type t = { enabled : bool [@default true] } [@@deriving make, show, yojson, eq]
  end

  module Status_checks = struct
    type t = {
      enabled : bool; [@default true]
      ignore_matching : string list; [@default []]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Check = struct
    type t = {
      approved : Approved.t; [@default Approved.make ()]
      merge_conflicts : Merge_conflicts.t; [@default Merge_conflicts.make ()]
      status_checks : Status_checks.t; [@default Status_checks.make ()]
      tag_query : Tag_query.t; [@default Terrat_tag_query.any]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Check_list = struct
    type t = Check.t list [@@deriving show, yojson, eq]
  end

  type t = {
    checks : Check_list.t; [@default [ Check.make ~approved:(Approved.make ~enabled:false ()) () ]]
    create_pending_apply_check : bool; [@default true]
  }
  [@@deriving make, show, yojson, eq]
end

module Automerge = struct
  type t = {
    delete_branch : bool; [@default false]
    enabled : bool; [@default false]
  }
  [@@deriving make, show, yojson, eq]
end

module Cost_estimation = struct
  module Provider = struct
    type t = Infracost [@@deriving show, yojson, eq]
  end

  type t = {
    currency : string; [@default "USD"]
    enabled : bool; [@default true]
    provider : Provider.t; [@default Provider.Infracost]
  }
  [@@deriving make, show, yojson, eq]
end

module Destination_branches = struct
  module Destination_branch = struct
    type t = {
      branch : string;
      source_branches : string list; [@default [ "*" ]]
    }
    [@@deriving make, show, yojson, eq]
  end

  type t = Destination_branch.t list [@@deriving show, yojson, eq]
end

module File_pattern = struct
  type t = {
    s : string;
    p : Path_glob.Glob.globber;
    negate : bool;
  }

  let sanitize = CCString.replace ~sub:"${DIR}" ~by:"\\$\\{DIR\\}"

  let make s =
    try
      if CCString.prefix ~pre:"!" s then
        Ok { s; p = Path_glob.Glob.parse ("<" ^ sanitize (CCString.drop 1 s) ^ ">"); negate = true }
      else Ok { s; p = Path_glob.Glob.parse ("<" ^ sanitize s ^ ">"); negate = false }
    with Path_glob.Glob.Parse_error err -> Error (`Glob_parse_err (s, err))

  let is_match { p; negate; _ } str =
    let m = Path_glob.Glob.eval p str in
    if negate then not m else m

  let is_negate { negate; _ } = negate
  let file_pattern { s; _ } = s
  let equal fp1 fp2 = CCString.equal (file_pattern fp1) (file_pattern fp2)
  let pp formatter { s; _ } = Format.fprintf formatter "%s" s
  let show { s; _ } = s
  let to_string { s; _ } = s
  let to_yojson { s; _ } = `String s

  let of_yojson = function
    | `String s -> CCResult.map_err (fun _ -> "Glob_parse_err " ^ s) (make s)
    | _ -> Error "Expected string"
end

module File_pattern_list = struct
  type t = File_pattern.t list [@@deriving show, yojson, eq]
end

module When_modified = struct
  type t = {
    autoapply : bool; [@default false]
    autoplan : bool; [@default true]
    autoplan_draft_pr : bool; [@default true]
    file_patterns : File_pattern_list.t;
        [@default
          [
            CCResult.get_exn (File_pattern.make "${DIR}/*.tf");
            CCResult.get_exn (File_pattern.make "${DIR}/*.tfvars");
          ]]
  }
  [@@deriving make, show, yojson, eq]
end

module Dirs = struct
  module Workspace = struct
    type t = { tags : string list [@default []] } [@@deriving make, show, yojson, eq]
  end

  module Dir = struct
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

module Drift = struct
  module Schedule = struct
    type t =
      | Hourly
      | Daily
      | Weekly
      | Monthly
    [@@deriving show, yojson, eq]

    let to_string = function
      | Hourly -> "hourly"
      | Daily -> "daily"
      | Weekly -> "weekly"
      | Monthly -> "monthly"
  end

  type t = {
    enabled : bool; [@default false]
    reconcile : bool; [@default false]
    schedule : Schedule.t; [@default Schedule.Weekly]
    tag_query : Tag_query.t; [@default Tag_query.any]
  }
  [@@deriving make, show, yojson, eq]
end

module Engine = struct
  module Cdktf = struct
    type t = {
      tf_cmd : string; [@default "terraform"]
      tf_version : string; [@default "latest"]
    }
    [@@deriving make, show, yojson, eq]
  end

  module Opentofu = struct
    type t = { version : string [@default "latest"] } [@@deriving make, show, yojson, eq]
  end

  module Terraform = struct
    type t = { version : string [@default "latest"] } [@@deriving make, show, yojson, eq]
  end

  module Terragrunt = struct
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

module Hooks = struct
  module Hook_op = struct
    type t =
      | Drift_create_issue
      | Env of Workflow_step.Env.t
      | Oidc of Workflow_step.Oidc.t
      | Run of Workflow_step.Run.t
    [@@deriving show, yojson, eq]
  end

  module Hook_op_list = struct
    type t = Hook_op.t list [@@deriving show, yojson, eq]
  end

  module Hook = struct
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

module Indexer = struct
  type t = {
    build_tag : string option;
    enabled : bool; [@default false]
  }
  [@@deriving make, show, yojson, eq]
end

module Integrations = struct
  module Resourcely = struct
    type t = {
      enabled : bool; [@default false]
      extra_args : string list; [@default []]
    }
    [@@deriving make, show, yojson, eq]
  end

  type t = { resourcely : Resourcely.t [@default Resourcely.make ()] }
  [@@deriving make, show, yojson, eq]
end

module Storage = struct
  module Plans = struct
    module Cmd = struct
      type t = {
        delete : Workflow_step.Cmd.t option;
        fetch : Workflow_step.Cmd.t;
        store : Workflow_step.Cmd.t;
      }
      [@@deriving make, show, yojson, eq]
    end

    module S3 = struct
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

module Tags = struct
  module Branch = struct
    type t = Pattern.t String_map.t [@@deriving show, yojson, eq]
  end

  type t = {
    branch : Branch.t; [@default String_map.empty]
    dest_branch : Branch.t; [@default String_map.empty]
  }
  [@@deriving make, show, yojson, eq]
end

module Workflows = struct
  module Entry = struct
    module Op = struct
      type t =
        | Init of Workflow_step.Init.t
        | Plan of Workflow_step.Plan.t
        | Apply of Workflow_step.Apply.t
        | Run of Workflow_step.Run.t
        | Env of Workflow_step.Env.t
        | Oidc of Workflow_step.Oidc.t
      [@@deriving show, yojson, eq]
    end

    module Op_list = struct
      type t = Op.t list [@@deriving show, yojson, eq]
    end

    module Lock_policy = struct
      type t =
        | Apply
        | Merge
        | None
        | Strict
      [@@deriving show, yojson, eq]

      let to_string = function
        | Apply -> "apply"
        | Merge -> "merge"
        | None -> "none"
        | Strict -> "strict"
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
  | `Unknown_plan_mode_err of string
  | `Workflows_apply_unknown_run_on_err of Terrat_repo_config_run_on.t
  | `Workflows_plan_unknown_run_on_err of Terrat_repo_config_run_on.t
  | `Workflows_tag_query_parse_err of string * string
  ]
[@@deriving show]

let default = make ()

(* Converters for the sub elements *)
let of_version_1_match = Access_control.Match.make
let of_version_1_match_list = CCResult.map_l of_version_1_match

let of_version_1_access_control_policies policies =
  let module Acp = Terrat_repo_config_access_control_policy in
  CCResult.map_l
    (fun {
           Acp.apply;
           apply_autoapprove;
           apply_force;
           apply_with_superapproval;
           plan;
           superapproval;
           tag_query;
         } ->
      let open CCResult.Infix in
      CCResult.map_err
        (function
          | `Tag_query_error err -> `Access_control_policy_tag_query_err err)
        (Terrat_tag_query.of_string tag_query)
      >>= fun tag_query ->
      CCResult.map_err
        (function
          | `Match_parse_err err -> `Access_control_policy_apply_match_parse_err err)
        (map_opt of_version_1_match_list apply)
      >>= fun apply ->
      CCResult.map_err
        (function
          | `Match_parse_err err -> `Access_control_policy_apply_autoapprove_match_parse_err err)
        (map_opt of_version_1_match_list apply_autoapprove)
      >>= fun apply_autoapprove ->
      CCResult.map_err
        (function
          | `Match_parse_err err -> `Access_control_policy_apply_force_match_parse_err err)
        (map_opt of_version_1_match_list apply_force)
      >>= fun apply_force ->
      CCResult.map_err
        (function
          | `Match_parse_err err ->
              `Access_control_policy_apply_with_superapproval_match_parse_err err)
        (map_opt of_version_1_match_list apply_with_superapproval)
      >>= fun apply_with_superapproval ->
      CCResult.map_err
        (function
          | `Match_parse_err err -> `Access_control_policy_plan_match_parse_err err)
        (map_opt of_version_1_match_list plan)
      >>= fun plan ->
      CCResult.map_err
        (function
          | `Match_parse_err err -> `Access_control_policy_superapproval_match_parse_err err)
        (map_opt of_version_1_match_list superapproval)
      >>= fun superapproval ->
      Ok
        (Access_control.Policy.make
           ?apply
           ?apply_autoapprove
           ?apply_force
           ?apply_with_superapproval
           ?plan
           ?superapproval
           ~tag_query
           ()))
    policies

let get_apply_requirements_checks_approved =
  let open CCResult.Infix in
  let module Ap = Terrat_repo_config.Apply_requirements_checks_approved in
  let module Ap1 = Terrat_repo_config.Apply_requirements_checks_approved_1 in
  let module Ap2 = Terrat_repo_config.Apply_requirements_checks_approved_2 in
  function
  | Ap.Apply_requirements_checks_approved_1 { Ap1.count; enabled } ->
      Ok (Apply_requirements.Approved.make ())
  | Ap.Apply_requirements_checks_approved_2 { Ap2.enabled; all_of; any_of; any_of_count } ->
      CCResult.map_err
        (function
          | `Match_parse_err err -> `Apply_requirements_approved_all_of_match_parse_err err)
        (map_opt of_version_1_match_list all_of)
      >>= fun all_of ->
      CCResult.map_err
        (function
          | `Match_parse_err err -> `Apply_requirements_approved_any_of_match_parse_err err)
        (map_opt of_version_1_match_list any_of)
      >>= fun any_of ->
      Ok (Apply_requirements.Approved.make ~enabled ?all_of ?any_of ~any_of_count ())

let get_apply_requirements_checks_merge_conflicts =
  let module Mc = Terrat_repo_config_apply_requirements_checks_merge_conflicts in
  fun { Mc.enabled } -> Ok (Apply_requirements.Merge_conflicts.make ~enabled ())

let get_apply_requirements_checks_status_checks =
  let module Sc = Terrat_repo_config_apply_requirements_checks_status_checks in
  fun { Sc.enabled; ignore_matching } ->
    Ok (Apply_requirements.Status_checks.make ~enabled ?ignore_matching ())

let of_version_1_apply_requirements_checks =
  let module Ar = Apply_requirements in
  let module Trc = Terrat_repo_config in
  let module Checks = Trc.Apply_requirements_checks in
  let module C1 = Terrat_repo_config.Apply_requirements_checks_1 in
  let module C2 = Terrat_repo_config.Apply_requirements_checks_2 in
  function
  | None -> Ok [ Ar.Check.make ~tag_query:Terrat_tag_query.any () ]
  | Some (Checks.Apply_requirements_checks_1 { C1.approved; merge_conflicts; status_checks }) ->
      let open CCResult.Infix in
      map_opt get_apply_requirements_checks_approved approved
      >>= fun approved ->
      map_opt get_apply_requirements_checks_merge_conflicts merge_conflicts
      >>= fun merge_conflicts ->
      map_opt get_apply_requirements_checks_status_checks status_checks
      >>= fun status_checks ->
      Ok
        [
          Ar.Check.make ~tag_query:Terrat_tag_query.any ?approved ?merge_conflicts ?status_checks ();
        ]
  | Some (Checks.Apply_requirements_checks_2 checks) ->
      let open CCResult.Infix in
      let module I = C2.Items in
      CCResult.map_l
        (fun { I.approved; merge_conflicts; status_checks; tag_query } ->
          CCResult.map_err
            (function
              | `Tag_query_error err -> `Apply_requirements_check_tag_query_err err)
            (Terrat_tag_query.of_string tag_query)
          >>= fun tag_query ->
          map_opt
            (fun ap ->
              get_apply_requirements_checks_approved
                (Trc.Apply_requirements_checks_approved.Apply_requirements_checks_approved_2 ap))
            approved
          >>= fun approved ->
          map_opt get_apply_requirements_checks_merge_conflicts merge_conflicts
          >>= fun merge_conflicts ->
          map_opt get_apply_requirements_checks_status_checks status_checks
          >>= fun status_checks ->
          Ok
            (Ar.Check.make
               ~tag_query:Terrat_tag_query.any
               ?approved
               ?merge_conflicts
               ?status_checks
               ()))
        checks

let of_version_1_workspace workspace =
  let module Ws = Terrat_repo_config_workspaces in
  let { Ws.Additional.tags } = workspace in
  Dirs.Workspace.make ~tags ()

let of_version_1_file_patterns fp = CCResult.map_l File_pattern.make fp

let of_version_1_dirs_when_modified default_when_modified when_modified =
  let open CCResult.Infix in
  let module Wm = When_modified in
  let module Wmn = Terrat_repo_config_when_modified_nullable in
  let { Wmn.autoapply; autoplan; autoplan_draft_pr; file_patterns } = when_modified in
  let default_when_modified =
    CCOption.get_or ~default:(When_modified.make ()) default_when_modified
  in
  map_opt of_version_1_file_patterns file_patterns
  >>= fun file_patterns ->
  Ok
    (When_modified.make
       ~autoapply:(CCOption.get_or ~default:default_when_modified.Wm.autoapply autoapply)
       ~autoplan:(CCOption.get_or ~default:default_when_modified.Wm.autoplan autoplan)
       ~autoplan_draft_pr:
         (CCOption.get_or ~default:default_when_modified.Wm.autoplan_draft_pr autoplan_draft_pr)
       ~file_patterns:
         (CCOption.get_or ~default:default_when_modified.Wm.file_patterns file_patterns)
       ())

let of_version_1_run_on =
  let module R = Workflow_step.Run_on in
  function
  | "failure" -> Ok R.Failure
  | "always" -> Ok R.Always
  | "success" -> Ok R.Success
  | v -> Error (`Unknown_run_on v)

let of_version_1_hook_op =
  let module Op = Terrat_repo_config_hook_op in
  function
  | Op.Hook_op_drift_create_issue _ -> Ok Hooks.Hook_op.Drift_create_issue
  | Op.Hook_op_env_exec op ->
      let module Op = Terrat_repo_config_hook_op_env_exec in
      let { Op.cmd; name; trim_trailing_newlines; method_ = _; type_ = _ } = op in
      Ok
        (Hooks.Hook_op.Env
           Workflow_step.Env.(Exec (Exec.make ~cmd ~name ~trim_trailing_newlines ())))
  | Op.Hook_op_env_source op ->
      let module Op = Terrat_repo_config_hook_op_env_source in
      let { Op.cmd; method_ = _; type_ = _ } = op in
      Ok (Hooks.Hook_op.Env Workflow_step.Env.(Source (Source.make ~cmd)))
  | Op.Hook_op_oidc op -> (
      let module Op = Terrat_repo_config_hook_op_oidc in
      let module Aws = Terrat_repo_config_hook_op_oidc_aws in
      let module Gcp = Terrat_repo_config_hook_op_oidc_gcp in
      match op with
      | Op.Hook_op_oidc_aws
          {
            Aws.assume_role_arn;
            assume_role_enabled;
            audience;
            duration;
            provider = _;
            region;
            role_arn;
            session_name;
            type_ = _;
          } ->
          Ok
            (Hooks.Hook_op.Oidc
               Workflow_step.Oidc.(
                 Aws
                   (Aws.make
                      ?assume_role_arn
                      ~assume_role_enabled
                      ?audience
                      ~duration
                      ~region
                      ~role_arn
                      ~session_name
                      ())))
      | Op.Hook_op_oidc_gcp
          {
            Gcp.access_token_lifetime;
            access_token_subject;
            audience;
            project_id;
            provider = _;
            service_account;
            type_ = _;
            workload_identity_provider;
          } ->
          Ok
            (Hooks.Hook_op.Oidc
               Workflow_step.Oidc.(
                 Gcp
                   (Gcp.make
                      ~access_token_lifetime
                      ?access_token_subject
                      ?audience
                      ?project_id
                      ~service_account
                      ~workload_identity_provider
                      ()))))
  | Op.Hook_op_run op ->
      let open CCResult.Infix in
      let module Op = Terrat_repo_config_hook_op_run in
      let { Op.capture_output; cmd; env; run_on; type_ = _ } = op in
      CCResult.map_err
        (function
          | `Unknown_run_on err -> `Hooks_unknown_run_on_err err)
        (map_opt of_version_1_run_on run_on)
      >>= fun run_on ->
      map_opt (fun { Op.Env.additional; _ } -> Ok additional) env
      >>= fun env ->
      Ok (Hooks.Hook_op.Run (Workflow_step.Run.make ~capture_output ~cmd ?env ?run_on ()))
  | Op.Hook_op_slack _ -> assert false

let of_version_1_drift_schedule = function
  | "hourly" -> Ok Drift.Schedule.Hourly
  | "daily" -> Ok Drift.Schedule.Daily
  | "weekly" -> Ok Drift.Schedule.Weekly
  | "monthly" -> Ok Drift.Schedule.Monthly
  | unknown -> Error (`Drift_schedule_err unknown)

let of_version_1_workflow_op_plan_mode = function
  | "strict" -> Ok Workflow_step.Plan.Mode.Strict
  | "fast-and-loose" -> Ok Workflow_step.Plan.Mode.Fast_and_loose
  | any -> Error (`Unknown_plan_mode_err any)

let of_version_1_workflow_op_list ops =
  let open CCResult.Infix in
  let module Op = Terrat_repo_config_workflow_op_list.Items in
  let module O = Workflows.Entry.Op in
  CCResult.map_l
    (function
      | Op.Workflow_op_init op ->
          let module Op = Terrat_repo_config_workflow_op_init in
          let { Op.env; extra_args; type_ = _ } = op in
          map_opt (fun { Op.Env.additional; _ } -> Ok additional) env
          >>= fun env -> Ok (O.Init (Workflow_step.Init.make ?env ?extra_args ()))
      | Op.Workflow_op_plan op ->
          let module Op = Terrat_repo_config_workflow_op_plan in
          let { Op.env; extra_args; mode; type_ = _ } = op in
          of_version_1_workflow_op_plan_mode mode
          >>= fun mode ->
          map_opt (fun { Op.Env.additional; _ } -> Ok additional) env
          >>= fun env -> Ok (O.Plan (Workflow_step.Plan.make ?env ?extra_args ~mode ()))
      | Op.Workflow_op_apply op ->
          let module R = Terrat_repo_config_retry in
          let module Op = Terrat_repo_config_workflow_op_apply in
          let { Op.env; extra_args; retry; type_ = _ } = op in
          map_opt (fun { Op.Env.additional; _ } -> Ok additional) env
          >>= fun env ->
          map_opt
            (fun { R.backoff; enabled; initial_sleep; tries } ->
              Ok (Workflow_step.Retry.make ~backoff ~enabled ~initial_sleep ~tries ()))
            retry
          >>= fun retry -> Ok (O.Apply (Workflow_step.Apply.make ?env ?extra_args ?retry ()))
      | Op.Hook_op_run op ->
          let module Op = Terrat_repo_config_hook_op_run in
          let { Op.capture_output; cmd; env; run_on; type_ = _ } = op in
          map_opt (fun { Op.Env.additional; _ } -> Ok additional) env
          >>= fun env ->
          CCResult.map_err
            (function
              | `Unknown_run_on err -> `Workflows_unknown_run_on_err err)
            (map_opt of_version_1_run_on run_on)
          >>= fun run_on -> Ok (O.Run (Workflow_step.Run.make ~capture_output ~cmd ?env ?run_on ()))
      | Op.Hook_op_slack _ -> assert false
      | Op.Hook_op_env_exec op ->
          let module Op = Terrat_repo_config_hook_op_env_exec in
          let { Op.cmd; name; trim_trailing_newlines; method_ = _; type_ = _ } = op in
          Ok (O.Env Workflow_step.Env.(Exec (Exec.make ~cmd ~name ~trim_trailing_newlines ())))
      | Op.Hook_op_env_source op ->
          let module Op = Terrat_repo_config_hook_op_env_source in
          let { Op.cmd; method_ = _; type_ = _ } = op in
          Ok (O.Env Workflow_step.Env.(Source (Source.make ~cmd)))
      | Op.Hook_op_oidc op -> (
          let module Op = Terrat_repo_config_hook_op_oidc in
          let module Aws = Terrat_repo_config_hook_op_oidc_aws in
          let module Gcp = Terrat_repo_config_hook_op_oidc_gcp in
          match op with
          | Op.Hook_op_oidc_aws
              {
                Aws.assume_role_arn;
                assume_role_enabled;
                audience;
                duration;
                provider = _;
                region;
                role_arn;
                session_name;
                type_ = _;
              } ->
              Ok
                (O.Oidc
                   Workflow_step.Oidc.(
                     Aws
                       (Aws.make
                          ?assume_role_arn
                          ~assume_role_enabled
                          ?audience
                          ~duration
                          ~region
                          ~role_arn
                          ~session_name
                          ())))
          | Op.Hook_op_oidc_gcp
              {
                Gcp.access_token_lifetime;
                access_token_subject;
                audience;
                project_id;
                provider = _;
                service_account;
                type_ = _;
                workload_identity_provider;
              } ->
              Ok
                (O.Oidc
                   Workflow_step.Oidc.(
                     Gcp
                       (Gcp.make
                          ~access_token_lifetime
                          ?access_token_subject
                          ?audience
                          ?project_id
                          ~service_account
                          ~workload_identity_provider
                          ())))))
    ops

let of_version_1_workflow_engine cdktf terraform_version terragrunt default_engine engine =
  let default_tf_cmd, default_tf_version, default_wrapper_version =
    match default_engine with
    | Some Engine.(Opentofu { Opentofu.version; _ }) -> (Some "tofu", Some version, None)
    | Some Engine.(Terragrunt { Terragrunt.tf_cmd; tf_version; version; _ }) ->
        (Some tf_cmd, Some tf_version, Some version)
    | _ -> (Some "terraform", None, None)
  in
  match (cdktf, terraform_version, terragrunt, engine) with
  | _, _, _, Some engine -> (
      let module E = Terrat_repo_config_engine in
      match engine with
      | E.Engine_cdktf cdktf ->
          let module E = Terrat_repo_config_engine_cdktf in
          Ok
            (Some
               Engine.(
                 Cdktf
                   (Cdktf.make
                      ?tf_cmd:(CCOption.or_ ~else_:default_tf_cmd cdktf.E.tf_cmd)
                      ?tf_version:(CCOption.or_ ~else_:default_tf_version cdktf.E.tf_version)
                      ())))
      | E.Engine_opentofu ot ->
          let module E = Terrat_repo_config_engine_opentofu in
          Ok
            (Some
               Engine.(
                 Opentofu
                   (Opentofu.make ?version:(CCOption.or_ ~else_:default_tf_version ot.E.version) ())))
      | E.Engine_terraform tf ->
          let module E = Terrat_repo_config_engine_terraform in
          Ok
            (Some
               Engine.(
                 Terraform
                   (Terraform.make
                      ?version:(CCOption.or_ ~else_:default_tf_version tf.E.version)
                      ())))
      | E.Engine_terragrunt tg ->
          let module E = Terrat_repo_config_engine_terragrunt in
          Ok
            (Some
               Engine.(
                 Terragrunt
                   (Terragrunt.make
                      ?tf_cmd:(CCOption.or_ ~else_:default_tf_cmd tg.E.tf_cmd)
                      ?tf_version:(CCOption.or_ ~else_:default_tf_version tg.E.tf_version)
                      ?version:(CCOption.or_ ~else_:default_wrapper_version tg.E.version)
                      ()))))
  | true, _, _, _ ->
      (* Cdktf *)
      Ok (Some Engine.(Cdktf (Cdktf.make ?tf_cmd:default_tf_cmd ?tf_version:default_tf_version ())))
  | _, Some terraform_version, _, None ->
      Ok (Some Engine.(Terraform (Terraform.make ~version:terraform_version ())))
  | _, _, true, None ->
      (* Terragrunt *)
      Ok
        (Some
           Engine.(
             Terragrunt
               (Terragrunt.make
                  ?tf_cmd:default_tf_cmd
                  ?tf_version:default_tf_version
                  ?version:default_wrapper_version
                  ())))
  | _, _, _, None -> Ok default_engine

let of_version_1_workflow_integrations default_integrations integrations =
  let open CCResult.Infix in
  let module I = Terrat_repo_config_integrations in
  match integrations with
  | Some { I.resourcely } ->
      map_opt
        (fun { I.Resourcely.enabled; extra_args } ->
          Ok (Integrations.Resourcely.make ~enabled ?extra_args ()))
        resourcely
      >>= fun resourcely -> Ok (Some (Integrations.make ?resourcely ()))
  | None -> Ok default_integrations

(* Converters for the top level fields *)
let of_version_1_access_control access_control =
  let open CCResult.Infix in
  let module Ac = Terrat_repo_config_access_control in
  let {
    Ac.apply_require_all_dirspace_access;
    enabled;
    plan_require_all_dirspace_access;
    policies;
    terrateam_config_update;
    unlock;
  } =
    access_control
  in
  CCResult.map_err
    (function
      | `Match_parse_err err -> `Access_control_terrateam_config_update_match_parse_err err)
    (map_opt of_version_1_match_list terrateam_config_update)
  >>= fun terrateam_config_update ->
  CCResult.map_err
    (function
      | `Match_parse_err err -> `Access_control_unlock_match_parse_err err)
    (map_opt of_version_1_match_list unlock)
  >>= fun unlock ->
  map_opt of_version_1_access_control_policies policies
  >>= fun policies ->
  Ok
    (Access_control.make
       ~apply_require_all_dirspace_access
       ~enabled
       ~plan_require_all_dirspace_access
       ?policies
       ?terrateam_config_update
       ?unlock
       ())

let of_version_1_apply_requirements apply_requirements =
  let open CCResult.Infix in
  let module Ar = Terrat_repo_config_apply_requirements in
  let { Ar.checks; create_pending_apply_check } = apply_requirements in
  of_version_1_apply_requirements_checks checks
  >>= fun checks -> Ok (Apply_requirements.make ~checks ~create_pending_apply_check ())

let of_version_automerge automerge =
  let module Am = Terrat_repo_config_automerge in
  let { Am.delete_branch; enabled } = automerge in
  Ok (Automerge.make ~delete_branch ~enabled ())

let of_version_1_cost_estimation { V1.Cost_estimation.currency; enabled; provider } =
  assert (provider = "infracost");
  Ok (Cost_estimation.make ~currency ~enabled ())

let of_version_1_destination_branches destination_branches =
  let module I = V1.Destination_branches.Items in
  let module Obj = Terrat_repo_config_destination_branch_object in
  let module Ds = Destination_branches.Destination_branch in
  CCResult.map_l
    (function
      | I.Destination_branch_name branch -> Ok (Ds.make ~branch ())
      | I.Destination_branch_object { Obj.branch; source_branches } ->
          Ok (Ds.make ~branch ?source_branches ()))
    destination_branches

let of_version_1_when_modified when_modified =
  let open CCResult.Infix in
  let module Wm = Terrat_repo_config_when_modified in
  let update_file_patterns =
    (* Put a ${DIR} in front of the default when modified.  The when modified
       configuration in the repo config implicitly has this.  In
       {!synthesize_dir_config} we are making the dir configuration to match every
       file, so we need the default config to work as if it were written as a dir
       config.

       The rule is if then when_modified entry starts with globbing, then we
       actually want to put the '${DIR}' in front.  For example, [*.hcl] should map
       to [${DIR}/*.hcl].  If it starts with [**] then we want to remove that and
       replace it with [${DIR}] so that it does not match subdirs. *)
    CCList.map (function
        | s when CCString.prefix ~pre:"!**/" s -> "!${DIR}/" ^ CCString.drop 4 s
        | s when CCString.prefix ~pre:"!*" s -> "!${DIR}/" ^ CCString.drop 1 s
        | s when CCString.prefix ~pre:"**/" s -> "${DIR}/" ^ CCString.drop 3 s
        | s when CCString.prefix ~pre:"*" s -> "${DIR}/" ^ s
        | s -> s)
  in
  let { Wm.autoapply; autoplan; autoplan_draft_pr; file_patterns } = when_modified in
  of_version_1_file_patterns (update_file_patterns file_patterns)
  >>= fun file_patterns ->
  Ok (When_modified.make ~autoapply ~autoplan ~autoplan_draft_pr ~file_patterns ())

let of_version_1_dirs default_when_modified { V1.Dirs.additional; _ } =
  let open CCResult.Infix in
  let module D = Terrat_repo_config_dir in
  let module Ws = Terrat_repo_config_workspaces in
  CCResult.map_l
    (fun (dir, { D.create_and_select_workspace; stacks; tags; when_modified; workspaces }) ->
      map_opt
        (fun { Ws.additional; _ } ->
          Ok
            (Json_schema.String_map.fold
               (fun key value acc -> String_map.add key (of_version_1_workspace value) acc)
               additional
               String_map.empty))
        stacks
      >>= fun stacks ->
      map_opt (of_version_1_dirs_when_modified default_when_modified) when_modified
      >>= fun when_modified ->
      let when_modified = CCOption.or_ ~else_:default_when_modified when_modified in
      map_opt
        (fun { Ws.additional; _ } ->
          Ok
            (Json_schema.String_map.fold
               (fun key value acc -> String_map.add key (of_version_1_workspace value) acc)
               additional
               String_map.empty))
        workspaces
      >>= fun workspaces ->
      Ok
        (dir, Dirs.Dir.make ~create_and_select_workspace ?stacks ?tags ?when_modified ?workspaces ()))
    (Json_schema.String_map.to_list additional)
  >>= fun dirs -> Ok (String_map.of_list dirs)

let of_version_1_drift drift =
  let open CCResult.Infix in
  let module Dr = Terrat_repo_config_drift in
  let { Dr.enabled; reconcile; schedule; tag_query } = drift in
  of_version_1_drift_schedule schedule
  >>= fun schedule ->
  CCResult.map_err
    (function
      | `Tag_query_error err -> `Drift_tag_query_err err)
    (map_opt Terrat_tag_query.of_string tag_query)
  >>= fun tag_query -> Ok (Drift.make ~enabled ~reconcile ~schedule ?tag_query ())

let of_version_1_engine default_tf_version engine =
  match (default_tf_version, engine) with
  | _, Some engine -> (
      let module E = Terrat_repo_config_engine in
      match engine with
      | E.Engine_cdktf cdktf ->
          let module E = Terrat_repo_config_engine_cdktf in
          Ok
            (Some
               Engine.(Cdktf (Cdktf.make ?tf_cmd:cdktf.E.tf_cmd ?tf_version:cdktf.E.tf_version ())))
      | E.Engine_opentofu ot ->
          let module E = Terrat_repo_config_engine_opentofu in
          Ok (Some Engine.(Opentofu (Opentofu.make ?version:ot.E.version ())))
      | E.Engine_terraform tf ->
          let module E = Terrat_repo_config_engine_terraform in
          Ok (Some Engine.(Terraform (Terraform.make ?version:tf.E.version ())))
      | E.Engine_terragrunt tg ->
          let module E = Terrat_repo_config_engine_terragrunt in
          Ok
            (Some
               Engine.(
                 Terragrunt
                   (Terragrunt.make
                      ?tf_cmd:tg.E.tf_cmd
                      ?tf_version:tg.E.tf_version
                      ?version:tg.E.version
                      ()))))
  | Some default_tf_version, _ ->
      Ok (Some Engine.(Terraform (Terraform.make ~version:default_tf_version ())))
  | None, None -> Ok None

let of_version_1_hooks_hook hook =
  let open CCResult.Infix in
  let module H = Terrat_repo_config_hook in
  let { H.post; pre } = hook in
  map_opt (CCResult.map_l of_version_1_hook_op) post
  >>= fun post ->
  map_opt (CCResult.map_l of_version_1_hook_op) pre
  >>= fun pre -> Ok (Hooks.Hook.make ?pre ?post ())

let of_version_1_hooks { V1.Hooks.all; apply; plan } =
  let open CCResult.Infix in
  map_opt of_version_1_hooks_hook all
  >>= fun all ->
  map_opt of_version_1_hooks_hook apply
  >>= fun apply ->
  map_opt of_version_1_hooks_hook plan >>= fun plan -> Ok (Hooks.make ?all ?apply ?plan ())

let of_version_1_indexer { V1.Indexer.build_tag; enabled } = Ok { Indexer.build_tag; enabled }

let of_version_1_integrations integrations =
  let module I = Terrat_repo_config_integrations in
  let { I.resourcely } = integrations in
  let resourcely =
    CCOption.map_or
      ~default:(Integrations.Resourcely.make ())
      (fun { I.Resourcely.enabled; extra_args } ->
        { Integrations.Resourcely.enabled; extra_args = CCOption.get_or ~default:[] extra_args })
      resourcely
  in
  Ok { Integrations.resourcely }

let of_version_1_storage storage =
  let open CCResult.Infix in
  let { V1.Storage.plans } = storage in
  CCOption.map_or
    ~default:(Ok Storage.Plans.Terrateam)
    (function
      | V1.Storage.Plans.Storage_plan_terrateam _ -> Ok Storage.Plans.Terrateam
      | V1.Storage.Plans.Storage_plan_cmd v ->
          let module Cmd = Terrat_repo_config_storage_plan_cmd in
          let { Cmd.delete; fetch; store; method_ = _ } = v in
          Ok Storage.Plans.(Cmd { Cmd.delete; fetch; store })
      | V1.Storage.Plans.Storage_plan_s3 v ->
          let module S3 = Terrat_repo_config_storage_plan_s3 in
          let {
            S3.access_key_id;
            bucket;
            delete_extra_args;
            delete_used_plans;
            fetch_extra_args;
            path;
            region;
            secret_access_key;
            store_extra_args;
            method_ = _;
          } =
            v
          in
          Ok
            Storage.Plans.(
              S3
                (S3.make
                   ?access_key_id
                   ~bucket
                   ?delete_extra_args
                   ~delete_used_plans
                   ?fetch_extra_args
                   ?path
                   ~region
                   ?secret_access_key
                   ?store_extra_args
                   ())))
    plans
  >>= fun plans -> Ok { Storage.plans }

let of_version_1_tags_branches branches =
  let module Tb = Terrat_repo_config_custom_tags_branch in
  let { Tb.additional = branches; _ } = branches in
  let open CCResult.Infix in
  CCResult.map_l
    (fun (k, s) -> Pattern.make s >>= fun p -> Ok (k, p))
    (Json_schema.String_map.to_list branches)
  >>= fun branches -> Ok (String_map.of_list branches)

let of_version_1_tags tags =
  let open CCResult.Infix in
  let module T = Terrat_repo_config_custom_tags in
  let module Tb = Terrat_repo_config_custom_tags_branch in
  let { T.branch; dest_branch } = tags in
  map_opt of_version_1_tags_branches branch
  >>= fun branch ->
  map_opt of_version_1_tags_branches dest_branch
  >>= fun dest_branch -> Ok (Tags.make ?branch ?dest_branch ())

let of_version_1_workflows_lock_policy = function
  | "apply" -> Ok Workflows.Entry.Lock_policy.Apply
  | "merge" -> Ok Workflows.Entry.Lock_policy.Merge
  | "none" -> Ok Workflows.Entry.Lock_policy.None
  | "strict" -> Ok Workflows.Entry.Lock_policy.Strict
  | any -> Error (`Unknown_lock_policy_err any)

let of_version_1_workflows default_engine default_integrations workflows =
  let open CCResult.Infix in
  let module E = Terrat_repo_config_workflow_entry in
  CCResult.map_l
    (fun {
           E.apply;
           cdktf;
           engine;
           environment;
           integrations;
           lock_policy;
           plan;
           tag_query;
           terraform_version;
           terragrunt;
         } ->
      CCResult.map_err
        (function
          | `Workflows_unknown_run_on_err err -> `Workflows_apply_unknown_run_on_err err
          | `Unknown_plan_mode_err _ -> assert false)
        (map_opt of_version_1_workflow_op_list apply)
      >>= fun apply ->
      of_version_1_workflow_engine cdktf terraform_version terragrunt default_engine engine
      >>= fun engine ->
      of_version_1_workflow_integrations default_integrations integrations
      >>= fun integrations ->
      of_version_1_workflows_lock_policy lock_policy
      >>= fun lock_policy ->
      CCResult.map_err
        (function
          | `Workflows_unknown_run_on_err err -> `Workflows_plan_unknown_run_on_err err
          | `Unknown_plan_mode_err _ as err -> err)
        (map_opt of_version_1_workflow_op_list plan)
      >>= fun plan ->
      CCResult.map_err
        (function
          | `Tag_query_error err -> `Workflows_tag_query_parse_err err)
        (Terrat_tag_query.of_string tag_query)
      >>= fun tag_query ->
      Ok
        (Workflows.Entry.make
           ?apply
           ?engine
           ?environment
           ?integrations
           ~lock_policy
           ?plan
           ~tag_query
           ()))
    workflows

let of_version_1 v1 =
  let {
    V1.access_control;
    apply_requirements;
    automerge;
    checkout_strategy = _;
    cost_estimation;
    create_and_select_workspace;
    default_tf_version;
    destination_branches;
    dirs;
    drift;
    enabled;
    engine;
    hooks;
    indexer;
    integrations;
    parallel_runs;
    storage;
    tags;
    version = _;
    when_modified;
    workflows;
  } =
    v1
  in
  let open CCResult.Infix in
  map_opt of_version_1_access_control access_control
  >>= fun access_control ->
  map_opt of_version_1_apply_requirements apply_requirements
  >>= fun apply_requirements ->
  map_opt of_version_automerge automerge
  >>= fun automerge ->
  map_opt of_version_1_cost_estimation cost_estimation
  >>= fun cost_estimation ->
  map_opt of_version_1_destination_branches destination_branches
  >>= fun destination_branches ->
  map_opt of_version_1_when_modified when_modified
  >>= fun when_modified ->
  map_opt (of_version_1_dirs when_modified) dirs
  >>= fun dirs ->
  map_opt of_version_1_drift drift
  >>= fun drift ->
  of_version_1_engine default_tf_version engine
  >>= fun engine ->
  map_opt of_version_1_hooks hooks
  >>= fun hooks ->
  map_opt of_version_1_indexer indexer
  >>= fun indexer ->
  map_opt of_version_1_integrations integrations
  >>= fun integrations ->
  map_opt of_version_1_storage storage
  >>= fun storage ->
  map_opt of_version_1_tags tags
  >>= fun tags ->
  map_opt (of_version_1_workflows engine integrations) workflows
  >>= fun workflows ->
  Ok
    (make
       ?access_control
       ?apply_requirements
       ?automerge
       ?cost_estimation
       ~create_and_select_workspace
       ?destination_branches
       ?dirs
       ?drift
       ~enabled
       ?engine
       ?hooks
       ?indexer
       ?integrations
       ~parallel_runs
       ?storage
       ?tags
       ?when_modified
       ?workflows
       ())

let to_version_1_match_list =
  CCList.map (function
      | Access_control.Match.User user -> "user:" ^ user
      | Access_control.Match.Team team -> "team:" ^ team
      | Access_control.Match.Repo repo -> "repo:" ^ repo
      | Access_control.Match.Any -> "*")

let to_version_1_policy_list =
  CCList.map
    (fun
      {
        Access_control.Policy.apply;
        apply_autoapprove;
        apply_force;
        apply_with_superapproval;
        plan;
        superapproval;
        tag_query;
      }
    ->
      let module P = Terrat_repo_config.Access_control_policy in
      {
        P.apply = Some (to_version_1_match_list apply);
        apply_autoapprove = Some (to_version_1_match_list apply_autoapprove);
        apply_force = Some (to_version_1_match_list apply_force);
        apply_with_superapproval = Some (to_version_1_match_list apply_with_superapproval);
        plan = Some (to_version_1_match_list plan);
        superapproval = Some (to_version_1_match_list superapproval);
        tag_query = Terrat_tag_query.to_string tag_query;
      })

let to_version_1_access_control ac =
  let module Ac = Terrat_repo_config.Access_control in
  {
    Ac.apply_require_all_dirspace_access = ac.Access_control.apply_require_all_dirspace_access;
    enabled = ac.Access_control.enabled;
    plan_require_all_dirspace_access = ac.Access_control.plan_require_all_dirspace_access;
    policies = Some (to_version_1_policy_list ac.Access_control.policies);
    terrateam_config_update =
      Some (to_version_1_match_list ac.Access_control.terrateam_config_update);
    unlock = Some (to_version_1_match_list ac.Access_control.unlock);
  }

let to_version_1_apply_requirements_approved approved =
  let module Ap = Terrat_repo_config.Apply_requirements_checks_approved_2 in
  let { Apply_requirements.Approved.all_of; any_of; any_of_count; enabled } = approved in
  {
    Ap.all_of = Some (to_version_1_match_list all_of);
    any_of = Some (to_version_1_match_list any_of);
    any_of_count;
    enabled;
  }

let to_version_1_apply_requirements_merge_conflicts mc =
  let module Mc = Terrat_repo_config.Apply_requirements_checks_merge_conflicts in
  let { Apply_requirements.Merge_conflicts.enabled } = mc in
  { Mc.enabled }

let to_version_1_apply_requirements_status_checks sc =
  let module Sc = Terrat_repo_config.Apply_requirements_checks_status_checks in
  let { Apply_requirements.Status_checks.enabled; ignore_matching } = sc in
  { Sc.enabled; ignore_matching = Some ignore_matching }

let to_version_1_apply_requirements_checks =
  let module C2 = Terrat_repo_config.Apply_requirements_checks_2 in
  CCList.map
    (fun { Apply_requirements.Check.approved; merge_conflicts; status_checks; tag_query } ->
      {
        C2.Items.approved = Some (to_version_1_apply_requirements_approved approved);
        merge_conflicts = Some (to_version_1_apply_requirements_merge_conflicts merge_conflicts);
        status_checks = Some (to_version_1_apply_requirements_status_checks status_checks);
        tag_query = Terrat_tag_query.to_string tag_query;
      })

let to_version_1_apply_requirements ar =
  let module Ar = Terrat_repo_config.Apply_requirements in
  let module C = Terrat_repo_config.Apply_requirements_checks in
  let { Apply_requirements.checks; create_pending_apply_check } = ar in
  {
    Ar.checks = Some (C.Apply_requirements_checks_2 (to_version_1_apply_requirements_checks checks));
    create_pending_apply_check;
  }

let to_version_1_automerge automerge =
  let module Am = Terrat_repo_config.Automerge in
  let { Automerge.delete_branch; enabled } = automerge in
  { Am.delete_branch; enabled }

let to_version_1_cost_estimation_provider = function
  | Cost_estimation.Provider.Infracost -> "infracost"

let to_version_1_cost_estimation cost_estimation =
  let module Ce = Terrat_repo_config.Version_1.Cost_estimation in
  let { Cost_estimation.currency; enabled; provider } = cost_estimation in
  { Ce.currency; enabled; provider = to_version_1_cost_estimation_provider provider }

let to_version_1_destination_branches db =
  let module Db = Terrat_repo_config.Version_1.Destination_branches in
  let module Obj = Terrat_repo_config.Destination_branch_object in
  CCList.map
    (fun { Destination_branches.Destination_branch.branch; source_branches } ->
      Db.Items.Destination_branch_object { Obj.branch; source_branches = Some source_branches })
    db

let to_version_1_dirs_dir_workspaces workspaces =
  let module Ws = Terrat_repo_config.Workspaces in
  Ws.make
    ~additional:
      (String_map.fold
         (fun k v acc ->
           let { Dirs.Workspace.tags } = v in
           Json_schema.String_map.add k { Ws.Additional.tags } acc)
         workspaces
         Json_schema.String_map.empty)
    Json_schema.Empty_obj.t

let to_version_1_dirs_dir_when_modified wm =
  let module Wm = Terrat_repo_config.When_modified_nullable in
  let { When_modified.autoapply; autoplan; autoplan_draft_pr; file_patterns } = wm in
  {
    Wm.autoapply = Some autoapply;
    autoplan = Some autoplan;
    autoplan_draft_pr = Some autoplan_draft_pr;
    file_patterns = Some (CCList.map File_pattern.to_string file_patterns);
  }

let to_version_1_dirs_dir dirs =
  let module D = Terrat_repo_config.Dir in
  String_map.fold
    (fun k v acc ->
      let { Dirs.Dir.create_and_select_workspace; stacks; tags; when_modified; workspaces } = v in
      Json_schema.String_map.add
        k
        {
          D.create_and_select_workspace;
          stacks =
            (if String_map.is_empty stacks then None
             else Some (to_version_1_dirs_dir_workspaces stacks));
          tags = Some tags;
          when_modified = Some (to_version_1_dirs_dir_when_modified when_modified);
          workspaces =
            (if String_map.is_empty workspaces then None
             else Some (to_version_1_dirs_dir_workspaces workspaces));
        }
        acc)
    dirs
    Json_schema.String_map.empty

let to_version_1_dirs dirs =
  let module Ds = Terrat_repo_config.Version_1.Dirs in
  Ds.make ~additional:(to_version_1_dirs_dir dirs) Json_schema.Empty_obj.t

let to_version_1_drift drift =
  let module D = Terrat_repo_config.Drift in
  let { Drift.enabled; reconcile; schedule; tag_query } = drift in
  {
    D.enabled;
    reconcile;
    schedule = Drift.Schedule.to_string schedule;
    tag_query = Some (Terrat_tag_query.to_string tag_query);
  }

let to_version_1_engine engine =
  let module E = Terrat_repo_config.Engine in
  match engine with
  | Engine.Cdktf cdktf ->
      let module Cdktf = Terrat_repo_config.Engine_cdktf in
      let { Engine.Cdktf.tf_cmd; tf_version } = cdktf in
      E.Engine_cdktf { Cdktf.name = "cdktf"; tf_cmd = Some tf_cmd; tf_version = Some tf_version }
  | Engine.Opentofu ot ->
      let module Ot = Terrat_repo_config.Engine_opentofu in
      let { Engine.Opentofu.version } = ot in
      E.Engine_opentofu { Ot.name = "tofu"; version = Some version }
  | Engine.Terraform tf ->
      let module Tf = Terrat_repo_config.Engine_terraform in
      let { Engine.Terraform.version } = tf in
      E.Engine_terraform { Tf.name = "terraform"; version = Some version }
  | Engine.Terragrunt tg ->
      let module Tg = Terrat_repo_config.Engine_terragrunt in
      let { Engine.Terragrunt.tf_cmd; tf_version; version } = tg in
      E.Engine_terragrunt
        {
          Tg.name = "terragrunt";
          tf_cmd = Some tf_cmd;
          tf_version = Some tf_version;
          version = Some version;
        }

let to_version_1_hooks_op_env_exec env =
  let module Op = Terrat_repo_config.Hook_op in
  let module E = Terrat_repo_config.Hook_op_env_exec in
  let { Workflow_step.Env.Exec.cmd; name; trim_trailing_newlines } = env in
  { E.cmd; method_ = Some "exec"; name; trim_trailing_newlines; type_ = "env" }

let to_version_1_hooks_op_env_source env =
  let module Op = Terrat_repo_config.Hook_op in
  let module E = Terrat_repo_config.Hook_op_env_source in
  let { Workflow_step.Env.Source.cmd } = env in
  { E.cmd; method_ = "source"; type_ = "env" }

let to_version_1_hooks_op_oidc = function
  | Workflow_step.Oidc.Aws oidc ->
      let module Oidc = Terrat_repo_config.Hook_op_oidc in
      let module Aws = Terrat_repo_config.Hook_op_oidc_aws in
      let {
        Workflow_step.Oidc.Aws.assume_role_arn;
        assume_role_enabled;
        audience;
        duration;
        region;
        role_arn;
        session_name;
      } =
        oidc
      in
      Oidc.Hook_op_oidc_aws
        {
          Aws.assume_role_arn;
          assume_role_enabled;
          audience;
          duration;
          provider = Some "aws";
          region;
          role_arn;
          session_name;
          type_ = "oidc";
        }
  | Workflow_step.Oidc.Gcp oidc ->
      let module Oidc = Terrat_repo_config.Hook_op_oidc in
      let module Gcp = Terrat_repo_config.Hook_op_oidc_gcp in
      let {
        Workflow_step.Oidc.Gcp.access_token_lifetime;
        access_token_subject;
        audience;
        project_id;
        service_account;
        workload_identity_provider;
      } =
        oidc
      in
      Oidc.Hook_op_oidc_gcp
        {
          Gcp.access_token_lifetime;
          access_token_subject;
          audience;
          project_id;
          provider = "gcp";
          service_account;
          type_ = "oidc";
          workload_identity_provider;
        }

let to_version_1_hooks_op_run r =
  let module R = Terrat_repo_config.Hook_op_run in
  let { Workflow_step.Run.capture_output; cmd; env; run_on } = r in
  {
    R.capture_output;
    cmd;
    env = CCOption.map (fun env -> R.Env.make ~additional:env Json_schema.Empty_obj.t) env;
    run_on = Some (Workflow_step.Run_on.to_string run_on);
    type_ = "run";
  }

let to_version_1_hooks_hook_list =
  let module Op = Terrat_repo_config.Hook_op in
  CCList.map (function
      | Hooks.Hook_op.Drift_create_issue ->
          let module D = Terrat_repo_config.Hook_op_drift_create_issue in
          Op.Hook_op_drift_create_issue { D.type_ = Some "drift_create_issue" }
      | Hooks.Hook_op.Env (Workflow_step.Env.Exec env) ->
          Op.Hook_op_env_exec (to_version_1_hooks_op_env_exec env)
      | Hooks.Hook_op.Env (Workflow_step.Env.Source env) ->
          Op.Hook_op_env_source (to_version_1_hooks_op_env_source env)
      | Hooks.Hook_op.Oidc oidc -> Op.Hook_op_oidc (to_version_1_hooks_op_oidc oidc)
      | Hooks.Hook_op.Run r -> Op.Hook_op_run (to_version_1_hooks_op_run r))

let to_version_1_hooks_hook hook =
  let module H = Terrat_repo_config.Hook in
  let { Hooks.Hook.pre; post } = hook in
  {
    H.post = Some (to_version_1_hooks_hook_list post);
    pre = Some (to_version_1_hooks_hook_list pre);
  }

let to_version_1_hooks hooks =
  let module H = Terrat_repo_config.Version_1.Hooks in
  let { Hooks.all; apply; plan } = hooks in
  {
    H.all = Some (to_version_1_hooks_hook all);
    apply = Some (to_version_1_hooks_hook apply);
    plan = Some (to_version_1_hooks_hook plan);
  }

let to_version_1_indexer indexer =
  let { Indexer.build_tag; enabled } = indexer in
  { V1.Indexer.build_tag; enabled }

let to_version_1_integrations integrations =
  let module I = Terrat_repo_config.Integrations in
  let { Integrations.resourcely = { Integrations.Resourcely.enabled; extra_args } } =
    integrations
  in
  { I.resourcely = Some { I.Resourcely.enabled; extra_args = Some [] } }

let to_version_1_storage_plans plans =
  match plans with
  | Storage.Plans.Terrateam ->
      let module S = Terrat_repo_config.Storage_plan_terrateam in
      V1.Storage.Plans.Storage_plan_terrateam { S.method_ = "terrateam" }
  | Storage.Plans.Cmd cmd ->
      let module S = Terrat_repo_config.Storage_plan_cmd in
      let { Storage.Plans.Cmd.delete; fetch; store } = cmd in
      V1.Storage.Plans.Storage_plan_cmd { S.delete; fetch; method_ = "cmd"; store }
  | Storage.Plans.S3 s3 ->
      let module S = Terrat_repo_config.Storage_plan_s3 in
      let {
        Storage.Plans.S3.access_key_id;
        bucket;
        delete_extra_args;
        delete_used_plans;
        fetch_extra_args;
        path;
        region;
        secret_access_key;
        store_extra_args;
      } =
        s3
      in
      V1.Storage.Plans.Storage_plan_s3
        {
          S.access_key_id;
          bucket;
          delete_extra_args = Some delete_extra_args;
          delete_used_plans;
          fetch_extra_args = Some fetch_extra_args;
          method_ = "s3";
          path;
          region;
          secret_access_key;
          store_extra_args = Some store_extra_args;
        }

let to_version_1_storage storage =
  let { Storage.plans } = storage in
  { V1.Storage.plans = Some (to_version_1_storage_plans plans) }

let to_version_1_tags_branch branch =
  Terrat_repo_config.Custom_tags_branch.make
    ~additional:
      (String_map.fold
         (fun k v acc -> Json_schema.String_map.add k (Pattern.to_string v) acc)
         branch
         Json_schema.String_map.empty)
    Json_schema.Empty_obj.t

let to_version_1_tags tags =
  let module T = Terrat_repo_config.Custom_tags in
  let { Tags.branch; dest_branch } = tags in
  {
    T.branch = Some (to_version_1_tags_branch branch);
    dest_branch = Some (to_version_1_tags_branch dest_branch);
  }

let to_version_1_when_modified when_modified =
  let module Wm = Terrat_repo_config.When_modified in
  let { When_modified.autoapply; autoplan; autoplan_draft_pr; file_patterns } = when_modified in
  {
    Wm.autoapply;
    autoplan;
    autoplan_draft_pr;
    file_patterns = CCList.map File_pattern.to_string file_patterns;
  }

let to_version_1_workflow_retry retry =
  let module R = Terrat_repo_config.Retry in
  let { Workflow_step.Retry.backoff; enabled; initial_sleep; tries } = retry in
  { R.backoff; enabled; initial_sleep; tries }

let to_version_1_workflows_op =
  let module Op = Terrat_repo_config.Workflow_op_list in
  CCList.map (function
      | Workflows.Entry.Op.Init init ->
          let module I = Terrat_repo_config.Workflow_op_init in
          let { Workflow_step.Init.env; extra_args } = init in
          Op.Items.Workflow_op_init
            {
              I.env =
                CCOption.map (fun env -> I.Env.make ~additional:env Json_schema.Empty_obj.t) env;
              extra_args = Some extra_args;
              type_ = "init";
            }
      | Workflows.Entry.Op.Plan plan ->
          let module P = Terrat_repo_config.Workflow_op_plan in
          let { Workflow_step.Plan.env; extra_args; mode } = plan in
          Op.Items.Workflow_op_plan
            {
              P.env =
                CCOption.map (fun env -> P.Env.make ~additional:env Json_schema.Empty_obj.t) env;
              extra_args = Some extra_args;
              mode = Workflow_step.Plan.Mode.to_string mode;
              type_ = "plan";
            }
      | Workflows.Entry.Op.Apply apply ->
          let module A = Terrat_repo_config.Workflow_op_apply in
          let { Workflow_step.Apply.env; extra_args; retry } = apply in
          Op.Items.Workflow_op_apply
            {
              A.env =
                CCOption.map (fun env -> A.Env.make ~additional:env Json_schema.Empty_obj.t) env;
              extra_args = Some extra_args;
              retry = CCOption.map to_version_1_workflow_retry retry;
              type_ = "apply";
            }
      | Workflows.Entry.Op.Run r -> Op.Items.Hook_op_run (to_version_1_hooks_op_run r)
      | Workflows.Entry.Op.Env (Workflow_step.Env.Exec env) ->
          Op.Items.Hook_op_env_exec (to_version_1_hooks_op_env_exec env)
      | Workflows.Entry.Op.Env (Workflow_step.Env.Source env) ->
          Op.Items.Hook_op_env_source (to_version_1_hooks_op_env_source env)
      | Workflows.Entry.Op.Oidc oidc -> Op.Items.Hook_op_oidc (to_version_1_hooks_op_oidc oidc))

let to_version_1_workflows =
  CCList.map (fun entry ->
      let module E = Terrat_repo_config.Workflow_entry in
      let { Workflows.Entry.apply; engine; environment; integrations; lock_policy; plan; tag_query }
          =
        entry
      in
      {
        E.apply = Some (to_version_1_workflows_op apply);
        cdktf = false;
        engine = Some (to_version_1_engine engine);
        environment;
        integrations =
          map_opt_if_true
            CCFun.(Integrations.equal (Integrations.make ()) %> not)
            to_version_1_integrations
            integrations;
        lock_policy = Workflows.Entry.Lock_policy.to_string lock_policy;
        plan = Some (to_version_1_workflows_op plan);
        tag_query = Terrat_tag_query.to_string tag_query;
        terraform_version = None;
        terragrunt = false;
      })

let to_version_1 t =
  let {
    access_control;
    apply_requirements;
    automerge;
    cost_estimation;
    create_and_select_workspace;
    destination_branches;
    dirs;
    drift;
    enabled;
    engine;
    hooks;
    indexer;
    integrations;
    parallel_runs;
    storage;
    tags;
    when_modified;
    workflows;
  } =
    t
  in
  {
    V1.access_control =
      map_opt_if_true
        CCFun.(Access_control.equal (Access_control.make ()) %> not)
        to_version_1_access_control
        access_control;
    apply_requirements =
      map_opt_if_true
        CCFun.(Apply_requirements.equal (Apply_requirements.make ()) %> not)
        to_version_1_apply_requirements
        apply_requirements;
    automerge =
      map_opt_if_true
        CCFun.(Automerge.equal (Automerge.make ()) %> not)
        to_version_1_automerge
        automerge;
    checkout_strategy = "merge";
    cost_estimation =
      map_opt_if_true
        CCFun.(Cost_estimation.equal (Cost_estimation.make ()) %> not)
        to_version_1_cost_estimation
        cost_estimation;
    create_and_select_workspace;
    default_tf_version = None;
    destination_branches =
      map_opt_if_true (( <> ) []) to_version_1_destination_branches destination_branches;
    dirs = map_opt_if_true CCFun.(String_map.is_empty %> not) to_version_1_dirs dirs;
    drift = map_opt_if_true CCFun.(Drift.equal (Drift.make ()) %> not) to_version_1_drift drift;
    enabled;
    engine =
      map_opt_if_true
        CCFun.(Engine.equal Engine.(Terraform (Terraform.make ())) %> not)
        to_version_1_engine
        engine;
    hooks = map_opt_if_true CCFun.(Hooks.equal (Hooks.make ()) %> not) to_version_1_hooks hooks;
    indexer =
      map_opt_if_true CCFun.(Indexer.equal (Indexer.make ()) %> not) to_version_1_indexer indexer;
    integrations =
      map_opt_if_true
        CCFun.(Integrations.equal (Integrations.make ()) %> not)
        to_version_1_integrations
        integrations;
    parallel_runs;
    storage =
      map_opt_if_true CCFun.(Storage.equal (Storage.make ()) %> not) to_version_1_storage storage;
    tags = map_opt_if_true CCFun.(Tags.equal (Tags.make ()) %> not) to_version_1_tags tags;
    version = "1";
    when_modified =
      map_opt_if_true
        CCFun.(When_modified.equal (When_modified.make ()) %> not)
        to_version_1_when_modified
        when_modified;
    workflows = map_opt_if_true (( <> ) []) to_version_1_workflows workflows;
  }

let merge_with_default_branch_config ~default t =
  {
    t with
    access_control = default.access_control;
    apply_requirements = default.apply_requirements;
    destination_branches = default.destination_branches;
  }
