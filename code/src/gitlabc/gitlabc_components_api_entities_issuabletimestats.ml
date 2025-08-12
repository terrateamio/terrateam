type t = {
  human_time_estimate : string option; [@default None]
  human_total_time_spent : string option; [@default None]
  time_estimate : int option; [@default None]
  total_time_spent : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
