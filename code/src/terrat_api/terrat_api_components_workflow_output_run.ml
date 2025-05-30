module Workflow_step = struct
  module Cmd = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Type = struct
    let t_of_yojson = function
      | `String "run" -> Ok "run"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    cmd : Cmd.t;
    exit_code : int option; [@default None]
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  outputs : Terrat_api_components_output_text.t option; [@default None]
  success : bool;
  workflow_step : Workflow_step.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
