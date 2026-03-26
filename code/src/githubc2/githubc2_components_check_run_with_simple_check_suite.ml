module Primary = struct
  module Conclusion = struct
    let t_of_yojson = function
      | `String "action_required" -> Ok `Action_required
      | `String "cancelled" -> Ok `Cancelled
      | `String "failure" -> Ok `Failure
      | `String "neutral" -> Ok `Neutral
      | `String "pending" -> Ok `Pending
      | `String "skipped" -> Ok `Skipped
      | `String "stale" -> Ok `Stale
      | `String "startup_failure" -> Ok `Startup_failure
      | `String "success" -> Ok `Success
      | `String "timed_out" -> Ok `Timed_out
      | `String "waiting" -> Ok `Waiting
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Action_required -> `String "action_required"
      | `Cancelled -> `String "cancelled"
      | `Failure -> `String "failure"
      | `Neutral -> `String "neutral"
      | `Pending -> `String "pending"
      | `Skipped -> `String "skipped"
      | `Stale -> `String "stale"
      | `Startup_failure -> `String "startup_failure"
      | `Success -> `String "success"
      | `Timed_out -> `String "timed_out"
      | `Waiting -> `String "waiting"

    type t =
      ([ `Action_required
       | `Cancelled
       | `Failure
       | `Neutral
       | `Pending
       | `Skipped
       | `Stale
       | `Startup_failure
       | `Success
       | `Timed_out
       | `Waiting
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Output = struct
    module Primary = struct
      type t = {
        annotations_count : int;
        annotations_url : string;
        summary : string option; [@default None]
        text : string option; [@default None]
        title : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Completed -> `String "completed"
      | `In_progress -> `String "in_progress"
      | `Pending -> `String "pending"
      | `Queued -> `String "queued"

    type t =
      ([ `Completed
       | `In_progress
       | `Pending
       | `Queued
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    app : Githubc2_components_nullable_integration.t option; [@default None]
    check_suite : Githubc2_components_simple_check_suite.t;
    completed_at : string option; [@default None]
    conclusion : Conclusion.t option; [@default None]
    deployment : Githubc2_components_deployment_simple.t option; [@default None]
    details_url : string;
    external_id : string;
    head_sha : string;
    html_url : string;
    id : int;
    name : string;
    node_id : string;
    output : Output.t;
    pull_requests : Pull_requests.t;
    started_at : string;
    status : Status_.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
