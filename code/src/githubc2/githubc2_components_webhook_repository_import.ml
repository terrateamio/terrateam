module Primary = struct
  module Status_ = struct
    let t_of_yojson = function
      | `String "cancelled" -> Ok `Cancelled
      | `String "failure" -> Ok `Failure
      | `String "success" -> Ok `Success
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Cancelled -> `String "cancelled"
      | `Failure -> `String "failure"
      | `Success -> `String "success"

    type t =
      ([ `Cancelled
       | `Failure
       | `Success
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t;
    status : Status_.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
