module Primary = struct
  module Conclusion = struct
    let t_of_yojson = function
      | `String "success" -> Ok "success"
      | `String "failure" -> Ok "failure"
      | `String "neutral" -> Ok "neutral"
      | `String "cancelled" -> Ok "cancelled"
      | `String "skipped" -> Ok "skipped"
      | `String "timed_out" -> Ok "timed_out"
      | `String "action_required" -> Ok "action_required"
      | `String "stale" -> Ok "stale"
      | `String "startup_failure" -> Ok "startup_failure"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Pull_requests = struct
    type t = Githubc2_components_pull_request_minimal.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Status_ = struct
    let t_of_yojson = function
      | `String "queued" -> Ok "queued"
      | `String "in_progress" -> Ok "in_progress"
      | `String "completed" -> Ok "completed"
      | `String "pending" -> Ok "pending"
      | `String "waiting" -> Ok "waiting"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    after : string option; [@default None]
    app : Githubc2_components_integration.t option; [@default None]
    before : string option; [@default None]
    conclusion : Conclusion.t option; [@default None]
    created_at : string option; [@default None]
    head_branch : string option; [@default None]
    head_sha : string option; [@default None]
    id : int option; [@default None]
    node_id : string option; [@default None]
    pull_requests : Pull_requests.t option; [@default None]
    repository : Githubc2_components_minimal_repository.t option; [@default None]
    status : Status_.t option; [@default None]
    updated_at : string option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
