(** A work manifest defines the work to be executed.   *)
module State : sig
  type t =
    | Queued
    | Running
    | Completed
    | Aborted

  val to_string : t -> string
  val of_string : string -> t option
end

module Kind : sig
  type ('pr, 'd, 'idx) t =
    | Pull_request of 'pr
    | Drift of 'd
    | Index of 'idx
end

module Run_type : sig
  type t =
    | Autoplan
    | Autoapply
    | Plan
    | Apply
    | Unsafe_apply

  val to_string : t -> string
  val of_string : string -> t option
end

module Unified_run_type : sig
  type t =
    | Plan
    | Apply

  val of_run_type : Run_type.t -> t
  val to_string : t -> string
end

module Deny : sig
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
  hash : string;
  id : 'id;
  run_id : 'run_id;
  run_type : 'run_type;
  src : 'src;
  state : 'state;
  tag_query : Terrat_tag_query.t;
  user : string option;
}

module New : sig
  (** A new work manifest has no id, create time, run id, or state *)
  type nonrec 'src t =
    (unit, unit, unit, unit, int Terrat_change.Dirspaceflow.t list, Deny.t list, 'src, Run_type.t) t
end

module Existing : sig
  (** An existing work manifest has all of the fillings *)
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

module Existing_lite : sig
  (** An existing work manifest but do not include the changes *)
  type nonrec 'src t = (Uuidm.t, string, string option, State.t, unit, unit, 'src, Run_type.t) t
end
