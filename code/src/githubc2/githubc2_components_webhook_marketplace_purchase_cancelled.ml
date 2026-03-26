module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "cancelled" -> Ok `Cancelled
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Cancelled -> `String "cancelled"

    type t = ([ `Cancelled ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    effective_date : string;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    marketplace_purchase : Githubc2_components_webhooks_marketplace_purchase.t;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    previous_marketplace_purchase :
      Githubc2_components_webhooks_previous_marketplace_purchase.t option;
        [@default None]
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
