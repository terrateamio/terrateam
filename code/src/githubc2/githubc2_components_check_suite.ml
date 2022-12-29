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
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    after : string option;
    app : Githubc2_components_nullable_integration.t option;
    before : string option;
    check_runs_url : string;
    conclusion : Conclusion.t option;
    created_at : string option;
    head_branch : string option;
    head_commit : Githubc2_components_simple_commit.t;
    head_sha : string;
    id : int;
    latest_check_runs_count : int;
    node_id : string;
    pull_requests : Pull_requests.t option;
    repository : Githubc2_components_minimal_repository.t;
    rerequestable : bool option; [@default None]
    runs_rerequestable : bool option; [@default None]
    status : Status_.t option;
    updated_at : string option;
    url : string option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
