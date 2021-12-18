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
  type t = {
    dirspace : Dirspace.t;
    workflow_idx : int option;
  }
  [@@deriving eq, show]

  val to_dirspace : t -> Dirspace.t
end
