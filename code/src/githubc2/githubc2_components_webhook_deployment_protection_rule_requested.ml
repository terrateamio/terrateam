module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "requested" -> Ok "requested"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Pull_requests = struct
    type t = Githubc2_components_pull_request.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t option; [@default None]
    deployment : Githubc2_components_deployment.t option; [@default None]
    deployment_callback_url : string option; [@default None]
    environment : string option; [@default None]
    event : string option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    pull_requests : Pull_requests.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    sender : Githubc2_components_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
