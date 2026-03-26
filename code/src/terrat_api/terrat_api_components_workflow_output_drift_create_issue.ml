module Workflow_step = struct
  module Type = struct
    let t_of_yojson = function
      | `String "drift-create-issue" -> Ok `Drift_create_issue
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Drift_create_issue -> `String "drift-create-issue"

    type t = ([ `Drift_create_issue ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { type_ : Type.t [@key "type"] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  outputs : Terrat_api_components_output_text.t option; [@default None]
  success : bool;
  workflow_step : Workflow_step.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
