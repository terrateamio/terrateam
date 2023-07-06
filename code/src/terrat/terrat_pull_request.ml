module State = struct
  module Merged = struct
    type t = {
      merged_hash : string;
      merged_at : string;
    }
    [@@deriving show]
  end

  module Open_status = struct
    type t =
      | Mergeable
      | Merge_conflict
    [@@deriving show]
  end

  type t =
    | Open of Open_status.t
    | Closed
    | Merged of Merged.t
  [@@deriving show]
end

type ('id, 'diff, 'checks) t = {
  base_branch_name : string;
  base_hash : string;
  branch_name : string;
  checks : 'checks;
  diff : 'diff;
  draft : bool;
  hash : string;
  id : 'id;
  mergeable : bool option;
  provisional_merge_sha : string option;
  state : State.t;
}
[@@deriving show]
