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
  module Workflow = struct
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

  let to_dirspace t = t.dirspace
end
