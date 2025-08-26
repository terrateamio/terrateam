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
  [@@deriving yojson, eq, show]
end

module Dirspace = Terrat_dirspace

module Dirspaceflow : sig
  module Workflow : sig
    type t = {
      idx : int;
      workflow : Terrat_base_repo_config_v1.Workflows.Entry.t;
    }
    [@@deriving eq, show]
  end

  type 'a t = {
    dirspace : Dirspace.t;
    workflow : 'a;
    variables : string Terrat_data.String_map.t option;
  }
  [@@deriving eq, show]

  val to_dirspace : 'a t -> Dirspace.t
end
