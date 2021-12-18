module Diff = struct
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

module Dirspace = struct
  type t = {
    dir : string;
    workspace : string;
  }
  [@@deriving eq, ord, show]
end

module Dirspaceflow = struct
  type t = {
    dirspace : Dirspace.t;
    workflow_idx : int option;
  }
  [@@deriving eq, show]

  let to_dirspace t = t.dirspace
end
