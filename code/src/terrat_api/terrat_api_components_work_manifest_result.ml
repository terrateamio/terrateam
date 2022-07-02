module Output = struct
  module Primary = struct
    module Cost_estimation = struct
      type t = {
        currency : string;
        diff_monthly_cost : float;
      }
      [@@deriving yojson { strict = true; meta = true }, show]
    end

    module Errors = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      cost_estimation : Cost_estimation.t option; [@default None]
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
  path : string;
  success : bool;
  workspace : string;
}
[@@deriving yojson { strict = true; meta = true }, show]
