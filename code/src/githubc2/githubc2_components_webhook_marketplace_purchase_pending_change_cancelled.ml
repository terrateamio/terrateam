module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "pending_change_cancelled" -> Ok "pending_change_cancelled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Marketplace_purchase_ = struct
    module All_of = struct
      module Primary = struct
        module Account = struct
          module Primary = struct
            type t = {
              id : int;
              login : string;
              node_id : string;
              organization_billing_email : string option;
              type_ : string; [@key "type"]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Free_trial_ends_on = struct
          type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
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
              unit_name : string option;
              yearly_price_in_cents : int;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          account : Account.t;
          billing_cycle : string;
          free_trial_ends_on : Free_trial_ends_on.t option;
          next_billing_date : string option;
          on_free_trial : bool;
          plan : Plan.t;
          unit_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module T = struct
      module Primary = struct
        module Account = struct
          module Primary = struct
            type t = {
              id : int;
              login : string;
              node_id : string;
              organization_billing_email : string option;
              type_ : string; [@key "type"]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Free_trial_ends_on = struct
          type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
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
              unit_name : string option;
              yearly_price_in_cents : int;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          account : Account.t;
          billing_cycle : string;
          free_trial_ends_on : Free_trial_ends_on.t option;
          next_billing_date : string option;
          on_free_trial : bool;
          plan : Plan.t;
          unit_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

    let of_yojson json =
      let open CCResult in
      flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
  end

  module Previous_marketplace_purchase = struct
    module Primary = struct
      module Account = struct
        module Primary = struct
          type t = {
            id : int;
            login : string;
            node_id : string;
            organization_billing_email : string option;
            type_ : string; [@key "type"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Free_trial_ends_on = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
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
            unit_name : string option;
            yearly_price_in_cents : int;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        account : Account.t;
        billing_cycle : string;
        free_trial_ends_on : Free_trial_ends_on.t option;
        next_billing_date : string option; [@default None]
        on_free_trial : bool;
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
    marketplace_purchase : Marketplace_purchase_.t;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    previous_marketplace_purchase : Previous_marketplace_purchase.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    sender : Githubc2_components_simple_user_webhooks.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)