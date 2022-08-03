type t = {
  currency : string;
  diff_monthly_cost : float option; [@default None]
  prev_monthly_cost : float option; [@default None]
  total_monthly_cost : float;
}
[@@deriving yojson { strict = true; meta = true }, show]
