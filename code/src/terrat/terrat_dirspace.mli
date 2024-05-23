(** A dirspace is the name given to the tuple of a directory and a workspace.
   This is the unit that an [apply] and [plan] can happen on. *)
type t = {
  dir : string;
  workspace : string;
}
[@@deriving eq, ord, show]
