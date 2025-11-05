module Capabilities = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Changed_dirspaces = struct
  type t = Terrat_api_components_work_manifest_dir.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Config = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type = struct
  let t_of_yojson = function
    | `String "apply" -> Ok "apply"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  api_base_url : string;
  base_ref : string;
  capabilities : Capabilities.t;
  changed_dirspaces : Changed_dirspaces.t;
  config : Config.t;
  installation_id : string;
  protocol_version : int option; [@default None]
  result_version : int;
  run_kind : string;
  token : string;
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
