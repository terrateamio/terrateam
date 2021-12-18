module Run_type = struct
  type t =
    | Autoplan
    | Autoapply
    | Plan
    | Apply

  let to_string = function
    | Autoplan -> "autoplan"
    | Plan -> "plan"
    | Autoapply -> "autoapply"
    | Apply -> "apply"

  let of_string = function
    | "autoplan" -> Some Autoplan
    | "plan" -> Some Plan
    | "autoapply" -> Some Autoapply
    | "apply" -> Some Apply
    | _ -> None
end

module Unified_run_type = struct
  type t =
    | Plan
    | Apply

  let of_run_type = function
    | Run_type.(Autoplan | Plan) -> Plan
    | Run_type.(Autoapply | Apply) -> Apply

  let to_string = function
    | Plan -> "plan"
    | Apply -> "apply"
end

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

type ('id, 'created_at, 'run_id, 'state, 'changes, 'pull_request) t = {
  base_hash : string;
  changes : 'changes;
  completed_at : string option;
  created_at : 'created_at;
  hash : string;
  id : 'id;
  pull_request : 'pull_request;
  run_id : 'run_id;
  run_type : Run_type.t;
  state : 'state;
  tag_query : Terrat_tag_set.t;
}

module New = struct
  type nonrec 'pull_request t =
    (unit, unit, unit, unit, Terrat_change.Dirspaceflow.t list, 'pull_request) t
end

module Existing = struct
  type nonrec 'pull_request t =
    (Uuidm.t, string, string option, State.t, Terrat_change.Dirspaceflow.t list, 'pull_request) t
end

module Existing_lite = struct
  type nonrec 'pull_request t = (Uuidm.t, string, string option, State.t, unit, 'pull_request) t
end
