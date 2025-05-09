module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "demilestoned" -> Ok "demilestoned"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    milestone : Githubc2_components_milestone.t option; [@default None]
    number : int;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    pull_request : Githubc2_components_webhooks_pull_request_5.t;
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
