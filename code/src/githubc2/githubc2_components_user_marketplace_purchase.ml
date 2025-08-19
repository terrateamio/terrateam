module Primary = struct
  type t = {
    account : Githubc2_components_marketplace_account.t;
    billing_cycle : string;
    free_trial_ends_on : string option; [@default None]
    next_billing_date : string option; [@default None]
    on_free_trial : bool;
    plan : Githubc2_components_marketplace_listing_plan.t;
    unit_count : int option; [@default None]
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
