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

module Kind = struct
  type ('pr, 'd, 'idx) t =
    | Pull_request of 'pr
    | Drift of 'd
    | Index of 'idx
end

module Run_type = struct
  type t =
    | Autoplan
    | Autoapply
    | Plan
    | Apply
    | Unsafe_apply

  let to_string = function
    | Autoplan -> "autoplan"
    | Plan -> "plan"
    | Autoapply -> "autoapply"
    | Apply -> "apply"
    | Unsafe_apply -> "unsafe-apply"

  let of_string = function
    | "autoplan" -> Some Autoplan
    | "plan" -> Some Plan
    | "autoapply" -> Some Autoapply
    | "apply" -> Some Apply
    | "unsafe-apply" -> Some Unsafe_apply
    | _ -> None
end

module Unified_run_type = struct
  type t =
    | Plan
    | Apply

  let of_run_type = function
    | Run_type.(Autoplan | Plan) -> Plan
    | Run_type.(Autoapply | Apply | Unsafe_apply) -> Apply

  let to_string = function
    | Plan -> "plan"
    | Apply -> "apply"
end

module Deny = struct
  type t = {
    dirspace : Terrat_change.Dirspace.t;
    policy : string list option;
  }
end

type ('id, 'created_at, 'run_id, 'state, 'changes, 'denied_dirspaces, 'src, 'run_type) t = {
  base_hash : string;
  changes : 'changes;
  completed_at : string option;
  created_at : 'created_at;
  denied_dirspaces : 'denied_dirspaces;
  environment : string option;
  hash : string;
  id : 'id;
  run_id : 'run_id;
  run_type : 'run_type;
  src : 'src;
  state : 'state;
  tag_query : Terrat_tag_query.t;
  user : string option;
}

module New = struct
  type nonrec 'src t =
    (unit, unit, unit, unit, int Terrat_change.Dirspaceflow.t list, Deny.t list, 'src, Run_type.t) t
end

module Existing = struct
  type nonrec 'src t =
    ( Uuidm.t,
      string,
      string option,
      State.t,
      int Terrat_change.Dirspaceflow.t list,
      Deny.t list,
      'src,
      Run_type.t )
    t
end

module Existing_lite = struct
  type nonrec 'src t = (Uuidm.t, string, string option, State.t, unit, unit, 'src, Run_type.t) t
end
