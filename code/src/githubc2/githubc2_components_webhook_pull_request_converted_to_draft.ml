module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "converted_to_draft" -> Ok `Converted_to_draft
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Converted_to_draft -> `String "converted_to_draft"

    type t = ([ `Converted_to_draft ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    number : int;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    pull_request : Githubc2_components_pull_request_webhook.t;
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
