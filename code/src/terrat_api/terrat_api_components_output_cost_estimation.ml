module Cost_estimation = struct
  module Dirspaces = struct
    module Items = struct
      type t = {
        diff_monthly_cost : float;
        path : string;
        prev_monthly_cost : float;
        total_monthly_cost : float;
        workspace : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    currency : string;
    diff_monthly_cost : float;
    dirspaces : Dirspaces.t;
    prev_monthly_cost : float;
    total_monthly_cost : float;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { cost_estimation : Cost_estimation.t }
[@@deriving yojson { strict = false; meta = true }, show, eq]
