type t = {
  account_status : string;
  id : string;
  name : string;
  tier : Terrat_api_components_tier.t;
  trial_ends_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
