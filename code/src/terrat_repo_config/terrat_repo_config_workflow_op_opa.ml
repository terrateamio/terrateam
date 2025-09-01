module Env = struct
  module Additional = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

module Extra_args = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type = struct
  let t_of_yojson = function
    | `String "opa" -> Ok "opa"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  env : Env.t option; [@default None]
  extra_args : Extra_args.t option; [@default None]
  gate : Terrat_repo_config_gate.t option; [@default None]
  ignore_errors : bool; [@default false]
  run_on : Terrat_repo_config_run_on.t option; [@default None]
  type_ : Type.t; [@key "type"]
  visible_on : Terrat_repo_config_visible_on.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
