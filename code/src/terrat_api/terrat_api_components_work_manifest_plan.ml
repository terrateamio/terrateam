module Base_dirspaces = struct
  type t = Terrat_api_components_work_manifest_dir.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Changed_dirspaces = struct
  type t = Terrat_api_components_work_manifest_dir.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Dirspaces = struct
  type t = Terrat_api_components_work_manifest_dir.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type = struct
  let t_of_yojson = function
    | `String "plan" -> Ok "plan"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  base_dirspaces : Base_dirspaces.t;
  base_ref : string;
  changed_dirspaces : Changed_dirspaces.t;
  dirspaces : Dirspaces.t;
  run_kind : string;
  token : string;
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
