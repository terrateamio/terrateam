module Primary = struct
  module Marketplace_pending_change = struct
    module Primary = struct
      type t = {
        effective_date : string option; [@default None]
        id : int option; [@default None]
        is_installed : bool option; [@default None]
        plan : Githubc2_components_marketplace_listing_plan.t option; [@default None]
        unit_count : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Marketplace_purchase_ = struct
    module Primary = struct
      type t = {
        billing_cycle : string option; [@default None]
        free_trial_ends_on : string option; [@default None]
        is_installed : bool option; [@default None]
        next_billing_date : string option; [@default None]
        on_free_trial : bool option; [@default None]
        plan : Githubc2_components_marketplace_listing_plan.t option; [@default None]
        unit_count : int option; [@default None]
        updated_at : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    email : string option; [@default None]
    id : int;
    login : string;
    marketplace_pending_change : Marketplace_pending_change.t option; [@default None]
    marketplace_purchase : Marketplace_purchase_.t;
    organization_billing_email : string option; [@default None]
    type_ : string; [@key "type"]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
