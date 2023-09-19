module State : sig
  module Merged : sig
    type t = {
      merged_hash : string;
      merged_at : string;
    }
    [@@deriving show]
  end

  module Open_status : sig
    type t =
      | Mergeable
      | Merge_conflict
    [@@deriving show]
  end

  type t =
    | Open of Open_status.t
    | Closed  (** The PR has been closed without merging *)
    | Merged of Merged.t  (** The PR has been closed by merging, we want the commit id *)
  [@@deriving show]
end

(** A service-agnostic definition of a pull request. *)
type ('id, 'diff, 'checks) t = {
  base_branch_name : string;
  base_hash : string;
  branch_name : string;
  checks : 'checks;
  diff : 'diff;
      (** The list of changes in the difference between [hash] and
                    [base_hash] *)
  draft : bool;
  hash : string;
  id : 'id;
  mergeable : bool option;
  provisional_merge_sha : string option;
  state : State.t;
  title : string option;
  user : string option;
}
[@@deriving show]
