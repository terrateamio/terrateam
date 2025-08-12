module Diff = struct
  type t =
    | Add of { filename : string }
    | Change of { filename : string }
    | Remove of { filename : string }
    | Move of {
        filename : string;
        previous_filename : string;
      }
  [@@deriving yojson, eq, show]
end

module Dirspace = Terrat_dirspace

module Dirspaceflow = struct
  module Workflow = struct
    type t = {
      idx : int;
      workflow : Terrat_base_repo_config_v1.Workflows.Entry.t;
    }
    [@@deriving eq, show]
  end

  type 'a t = {
    dirspace : Dirspace.t;
    workflow : 'a;
  }
  [@@deriving eq, show]

  let to_dirspace t = t.dirspace
end
