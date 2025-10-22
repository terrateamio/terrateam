module Dirspaces = struct
  type t = Terrat_api_components_dirspace.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Paths = struct
  type t = Terrat_api_components_stack_path.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  dirspaces : Dirspaces.t option; [@default None]
  name : string;
  paths : Paths.t;
  state : Terrat_api_components_stack_state.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
