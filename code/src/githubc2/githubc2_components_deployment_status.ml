module Primary = struct
  module State = struct
    let t_of_yojson = function
      | `String "error" -> Ok "error"
      | `String "failure" -> Ok "failure"
      | `String "inactive" -> Ok "inactive"
      | `String "pending" -> Ok "pending"
      | `String "success" -> Ok "success"
      | `String "queued" -> Ok "queued"
      | `String "in_progress" -> Ok "in_progress"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    created_at : string;
    creator : Githubc2_components_nullable_simple_user.t option;
    deployment_url : string;
    description : string; [@default ""]
    environment : string; [@default ""]
    environment_url : string; [@default ""]
    id : int;
    log_url : string; [@default ""]
    node_id : string;
    performed_via_github_app : Githubc2_components_nullable_integration.t option; [@default None]
    repository_url : string;
    state : State.t;
    target_url : string; [@default ""]
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
