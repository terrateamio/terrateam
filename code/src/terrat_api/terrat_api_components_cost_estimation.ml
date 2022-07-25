type t = {
  currency : string;
  diff_monthly_cost : float;
  prev_monthly_cost : float;
  total_monthly_cost : float;
}
[@@deriving yojson { strict = true; meta = true }, show]
