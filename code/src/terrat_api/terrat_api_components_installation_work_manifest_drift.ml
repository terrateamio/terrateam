module Dirspaces = struct
  type t = Terrat_api_components_work_manifest_dirspace.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  base_branch : string;
  base_ref : string;
  completed_at : string option; [@default None]
  created_at : string;
  dirspaces : Dirspaces.t;
  environment : string option; [@default None]
  id : string;
  owner : string;
  ref_ : string; [@key "ref"]
  repo : string;
  repository : int;
  run_id : string option; [@default None]
  run_type : Terrat_api_components_run_type.t;
  state : Terrat_api_components_work_manifest_state.t;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
