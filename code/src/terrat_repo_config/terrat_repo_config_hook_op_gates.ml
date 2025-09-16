module Cmd = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Env = struct
  module Additional = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

module Type = struct
  let t_of_yojson = function
    | `String "gates" -> Ok "gates"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  cmd : Cmd.t;
  env : Env.t option; [@default None]
  run_on : Terrat_repo_config_run_on.t option; [@default None]
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
