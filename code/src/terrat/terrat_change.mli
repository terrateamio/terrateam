(** A change that is a diff. *)
module Diff : sig
  type t =
    | Add of { filename : string }
    | Change of { filename : string }
    | Remove of { filename : string }
    | Move of {
        filename : string;
        previous_filename : string;
      }
  [@@deriving eq, show]
end

(** A dirspace is the name given to the tuple of a directory and a workspace.
   This is the unit that an [apply] and [plan] can happen on. *)
module Dirspace : sig
  type t = {
    dir : string;
    workspace : string;
  }
  [@@deriving eq, ord, show]
end

module Dirspaceflow : sig
  module Workflow : sig
    type t = {
      idx : int;
      workflow : Terrat_repo_config_workflow_entry.t;
    }
    [@@deriving eq, show]
  end

  type 'a t = {
    dirspace : Dirspace.t;
    workflow : 'a option;
  }
  [@@deriving eq, show]

  val to_dirspace : 'a t -> Dirspace.t
end
