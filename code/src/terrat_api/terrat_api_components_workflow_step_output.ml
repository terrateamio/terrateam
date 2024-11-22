module Payload = struct
  module Additional = struct
    type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

type t = {
  ignore_errors : bool;
  payload : Payload.t;
  scope : Terrat_api_components_workflow_step_output_scope.t;
  step : string;
  success : bool;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
