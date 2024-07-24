module State = struct
  type t =
    | Queued
    | Running
    | Completed
    | Aborted

  let to_string = function
    | Queued -> "queued"
    | Running -> "running"
    | Completed -> "completed"
    | Aborted -> "aborted"

  let of_string = function
    | "queued" -> Some Queued
    | "running" -> Some Running
    | "completed" -> Some Completed
    | "aborted" -> Some Aborted
    | _ -> None
end

module Step = struct
  type t =
    | Apply
    | Index
    | Plan
    | Unsafe_apply

  let to_string = function
    | Plan -> "plan"
    | Index -> "index"
    | Apply -> "apply"
    | Unsafe_apply -> "unsafe-apply"

  let of_string = function
    | "plan" -> Some Plan
    | "index" -> Some Index
    | "apply" -> Some Apply
    | "unsafe-apply" -> Some Unsafe_apply
    (* Legacy conversions *)
    | "autoplan" -> Some Plan
    | "autoapply" -> Some Apply
    | _ -> None
end

module Deny = struct
  type t = {
    dirspace : Terrat_change.Dirspace.t;
    policy : Terrat_base_repo_config_v1.Access_control.Match_list.t option;
  }
end

module Initiator = struct
  type t =
    | User of string
    | System
end

type ('account, 'id, 'created_at, 'run_id, 'state, 'changes, 'denied_dirspaces, 'target) t = {
  account : 'account;
  base_ref : string;
  branch_ref : string;
  changes : 'changes;
  completed_at : string option;
  created_at : 'created_at;
  denied_dirspaces : 'denied_dirspaces;
  environment : string option;
  id : 'id;
  initiator : Initiator.t;
  run_id : 'run_id;
  state : 'state;
  steps : Step.t list;
  tag_query : Terrat_tag_query.t;
  target : 'target;
}

module New = struct
  (** A new work manifest has no id, create time, run id, or state *)
  type nonrec ('account, 'target) t =
    ( 'account,
      unit,
      unit,
      unit,
      unit,
      int Terrat_change.Dirspaceflow.t list,
      Deny.t list,
      'target )
    t
end

module Existing = struct
  (** An existing work manifest has all of the fillings *)
  type nonrec ('account, 'target) t =
    ( 'account,
      Uuidm.t,
      string,
      string option,
      State.t,
      int Terrat_change.Dirspaceflow.t list,
      Deny.t list,
      'target )
    t
end
