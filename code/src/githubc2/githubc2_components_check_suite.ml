module Primary = struct
  module Conclusion = struct
    let t_of_yojson = function
      | `String "action_required" -> Ok `Action_required
      | `String "cancelled" -> Ok `Cancelled
      | `String "failure" -> Ok `Failure
      | `String "neutral" -> Ok `Neutral
      | `String "skipped" -> Ok `Skipped
      | `String "stale" -> Ok `Stale
      | `String "startup_failure" -> Ok `Startup_failure
      | `String "success" -> Ok `Success
      | `String "timed_out" -> Ok `Timed_out
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Action_required -> `String "action_required"
      | `Cancelled -> `String "cancelled"
      | `Failure -> `String "failure"
      | `Neutral -> `String "neutral"
      | `Skipped -> `String "skipped"
      | `Stale -> `String "stale"
      | `Startup_failure -> `String "startup_failure"
      | `Success -> `String "success"
      | `Timed_out -> `String "timed_out"

    type t =
      ([ `Action_required
       | `Cancelled
       | `Failure
       | `Neutral
       | `Skipped
       | `Stale
       | `Startup_failure
       | `Success
       | `Timed_out
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Pull_requests = struct
    type t = Githubc2_components_pull_request_minimal.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Status_ = struct
    let t_of_yojson = function
      | `String "completed" -> Ok `Completed
      | `String "in_progress" -> Ok `In_progress
      | `String "pending" -> Ok `Pending
      | `String "queued" -> Ok `Queued
      | `String "requested" -> Ok `Requested
      | `String "waiting" -> Ok `Waiting
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Completed -> `String "completed"
      | `In_progress -> `String "in_progress"
      | `Pending -> `String "pending"
      | `Queued -> `String "queued"
      | `Requested -> `String "requested"
      | `Waiting -> `String "waiting"

    type t =
      ([ `Completed
       | `In_progress
       | `Pending
       | `Queued
       | `Requested
       | `Waiting
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    after : string option; [@default None]
    app : Githubc2_components_nullable_integration.t option; [@default None]
    before : string option; [@default None]
    check_runs_url : string;
    conclusion : Conclusion.t option; [@default None]
    created_at : string option; [@default None]
    head_branch : string option; [@default None]
    head_commit : Githubc2_components_simple_commit.t;
    head_sha : string;
    id : int64;
    latest_check_runs_count : int;
    node_id : string;
    pull_requests : Pull_requests.t option; [@default None]
    repository : Githubc2_components_minimal_repository.t;
    rerequestable : bool option; [@default None]
    runs_rerequestable : bool option; [@default None]
    status : Status_.t option; [@default None]
    updated_at : string option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
