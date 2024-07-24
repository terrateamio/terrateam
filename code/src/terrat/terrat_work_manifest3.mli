module State : sig
  type t =
    | Queued
    | Running
    | Completed
    | Aborted

  val to_string : t -> string
  val of_string : string -> t option
end

module Step : sig
  type t =
    | Apply
    | Index
    | Plan
    | Unsafe_apply

  val to_string : t -> string
  val of_string : string -> t option
end

module Deny : sig
  type t = {
    dirspace : Terrat_change.Dirspace.t;
    policy : Terrat_base_repo_config_v1.Access_control.Match_list.t option;
  }
end

module Initiator : sig
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

module New : sig
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

module Existing : sig
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
