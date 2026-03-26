module Primary = struct
  module State = struct
    let t_of_yojson = function
      | `String "error" -> Ok `Error
      | `String "failure" -> Ok `Failure
      | `String "in_progress" -> Ok `In_progress
      | `String "inactive" -> Ok `Inactive
      | `String "pending" -> Ok `Pending
      | `String "queued" -> Ok `Queued
      | `String "success" -> Ok `Success
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Error -> `String "error"
      | `Failure -> `String "failure"
      | `In_progress -> `String "in_progress"
      | `Inactive -> `String "inactive"
      | `Pending -> `String "pending"
      | `Queued -> `String "queued"
      | `Success -> `String "success"

    type t =
      ([ `Error
       | `Failure
       | `In_progress
       | `Inactive
       | `Pending
       | `Queued
       | `Success
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string;
    creator : Githubc2_components_nullable_simple_user.t option; [@default None]
    deployment_url : string;
    description : string; [@default ""]
    environment : string; [@default ""]
    environment_url : string; [@default ""]
    id : int64;
    log_url : string; [@default ""]
    node_id : string;
    performed_via_github_app : Githubc2_components_nullable_integration.t option; [@default None]
    repository_url : string;
    state : State.t;
    target_url : string; [@default ""]
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
