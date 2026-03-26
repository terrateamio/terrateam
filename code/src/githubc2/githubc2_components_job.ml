module Primary = struct
  module Conclusion = struct
    let t_of_yojson = function
      | `String "action_required" -> Ok `Action_required
      | `String "cancelled" -> Ok `Cancelled
      | `String "failure" -> Ok `Failure
      | `String "neutral" -> Ok `Neutral
      | `String "skipped" -> Ok `Skipped
      | `String "success" -> Ok `Success
      | `String "timed_out" -> Ok `Timed_out
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Action_required -> `String "action_required"
      | `Cancelled -> `String "cancelled"
      | `Failure -> `String "failure"
      | `Neutral -> `String "neutral"
      | `Skipped -> `String "skipped"
      | `Success -> `String "success"
      | `Timed_out -> `String "timed_out"

    type t =
      ([ `Action_required
       | `Cancelled
       | `Failure
       | `Neutral
       | `Skipped
       | `Success
       | `Timed_out
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Labels = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
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

  module Steps = struct
    module Items = struct
      module Primary = struct
        module Status_ = struct
          let t_of_yojson = function
            | `String "completed" -> Ok `Completed
            | `String "in_progress" -> Ok `In_progress
            | `String "queued" -> Ok `Queued
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          let t_to_yojson = function
            | `Completed -> `String "completed"
            | `In_progress -> `String "in_progress"
            | `Queued -> `String "queued"

          type t =
            ([ `Completed
             | `In_progress
             | `Queued
             ]
            [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = {
          completed_at : string option; [@default None]
          conclusion : string option; [@default None]
          name : string;
          number : int;
          started_at : string option; [@default None]
          status : Status_.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    check_run_url : string;
    completed_at : string option; [@default None]
    conclusion : Conclusion.t option; [@default None]
    created_at : string;
    head_branch : string option; [@default None]
    head_sha : string;
    html_url : string option; [@default None]
    id : int;
    labels : Labels.t;
    name : string;
    node_id : string;
    run_attempt : int option; [@default None]
    run_id : int;
    run_url : string;
    runner_group_id : int option; [@default None]
    runner_group_name : string option; [@default None]
    runner_id : int option; [@default None]
    runner_name : string option; [@default None]
    started_at : string;
    status : Status_.t;
    steps : Steps.t option; [@default None]
    url : string;
    workflow_name : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
