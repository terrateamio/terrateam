module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "changed" -> Ok "changed"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Previous_marketplace_purchase = struct
    module Primary = struct
      module Account = struct
        module Primary = struct
          type t = {
            id : int;
            login : string;
            node_id : string;
            organization_billing_email : string option; [@default None]
            type_ : string; [@key "type"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Plan = struct
        module Primary = struct
          module Bullets = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Price_model = struct
            let t_of_yojson = function
              | `String "FREE" -> Ok "FREE"
              | `String "FLAT_RATE" -> Ok "FLAT_RATE"
              | `String "PER_UNIT" -> Ok "PER_UNIT"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            bullets : Bullets.t;
            description : string;
            has_free_trial : bool;
            id : int;
            monthly_price_in_cents : int;
            name : string;
            price_model : Price_model.t;
            unit_name : string option; [@default None]
            yearly_price_in_cents : int;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        account : Account.t;
        billing_cycle : string;
        free_trial_ends_on : string option; [@default None]
        next_billing_date : string option; [@default None]
        on_free_trial : bool option; [@default None]
        plan : Plan.t;
        unit_count : int;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    effective_date : string;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    marketplace_purchase : Githubc2_components_webhooks_marketplace_purchase.t;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    previous_marketplace_purchase : Previous_marketplace_purchase.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
