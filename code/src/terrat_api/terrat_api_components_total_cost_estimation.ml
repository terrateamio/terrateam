type t = {
  currency : string;
  total_monthly_cost : float;
}
[@@deriving yojson { strict = true; meta = true }, show]
