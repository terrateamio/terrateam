module State = struct
  module Merged = struct
    type t = {
      merged_hash : string;
      merged_at : string;
    }
    [@@deriving show]
  end

  type t =
    | Open
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
  hash : string;
  id : 'id;
  mergeable : bool option;
  state : State.t;
}
[@@deriving show]