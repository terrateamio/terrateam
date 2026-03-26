module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "destroyed" -> Ok `Destroyed
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Destroyed -> `String "destroyed"

    type t = ([ `Destroyed ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Reason = struct
    let t_of_yojson = function
      | `String "dequeued" -> Ok `Dequeued
      | `String "invalidated" -> Ok `Invalidated
      | `String "merged" -> Ok `Merged
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Dequeued -> `String "dequeued"
      | `Invalidated -> `String "invalidated"
      | `Merged -> `String "merged"

    type t =
      ([ `Dequeued
       | `Invalidated
       | `Merged
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    installation : Githubc2_components_simple_installation.t option; [@default None]
    merge_group : Githubc2_components_merge_group.t;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    reason : Reason.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    sender : Githubc2_components_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
