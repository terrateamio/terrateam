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

type ('id, 'created_at, 'run_id, 'state, 'changes, 'src, 'run_type) t = {
  base_hash : string;
  changes : 'changes;
  completed_at : string option;
  created_at : 'created_at;
  hash : string;
  id : 'id;
  src : 'src;
  run_id : 'run_id;
  run_type : 'run_type;
  state : 'state;
  tag_query : Terrat_tag_query.t;
}

module Pull_request : sig
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

  module New : sig
    (** A new work manifest has no id, create time, run id, or state *)
    type nonrec 'pull_request t =
      (unit, unit, unit, unit, Terrat_change.Dirspaceflow.t list, 'pull_request, Run_type.t) t
  end

  module Existing : sig
    (** An existing work manifest has all of the fillings *)
    type nonrec 'pull_request t =
      ( Uuidm.t,
        string,
        string option,
        State.t,
        Terrat_change.Dirspaceflow.t list,
        'pull_request,
        Run_type.t )
      t
  end

  module Existing_lite : sig
    (** An existing work manifest but do not include the changes *)
    type nonrec 'pull_request t =
      (Uuidm.t, string, string option, State.t, unit, 'pull_request, Run_type.t) t
  end
end
