module Output = struct
  module Primary = struct
    module Errors = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      cost_estimation : Terrat_api_components_cost_estimation.t option; [@default None]
      errors : Errors.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Additional = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Additional)
end

type t = {
  output : Output.t;
  outputs : Terrat_api_components_workflow_outputs.t option; [@default None]
  path : string;
  success : bool;
  workspace : string;
}
[@@deriving yojson { strict = true; meta = true }, show]
