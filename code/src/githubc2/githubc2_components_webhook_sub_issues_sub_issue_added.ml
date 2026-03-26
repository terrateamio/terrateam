module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "sub_issue_added" -> Ok `Sub_issue_added
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Sub_issue_added -> `String "sub_issue_added"

    type t = ([ `Sub_issue_added ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    parent_issue : Githubc2_components_issue.t;
    parent_issue_id : float;
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    sender : Githubc2_components_simple_user.t option; [@default None]
    sub_issue : Githubc2_components_issue.t;
    sub_issue_id : float;
    sub_issue_repo : Githubc2_components_repository.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
