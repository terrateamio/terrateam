module Dirspaces = struct
  type t = Terrat_api_components_work_manifest_dirspace.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Run_type = struct
  let t_of_yojson = function
    | `String "apply" -> Ok "apply"
    | `String "autoapply" -> Ok "autoapply"
    | `String "autoplan" -> Ok "autoplan"
    | `String "plan" -> Ok "plan"
    | `String "unsafe-apply" -> Ok "unsafe-apply"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  base_branch : string;
  base_ref : string;
  completed_at : string option; [@default None]
  created_at : string;
  dirspaces : Dirspaces.t;
  id : string;
  owner : string;
  ref_ : string; [@key "ref"]
  repo : string;
  repository : int;
  run_id : string option; [@default None]
  run_type : Run_type.t;
  state : Terrat_api_components_work_manifest_state.t;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
