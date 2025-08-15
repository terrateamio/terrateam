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

  module Labels = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Status_ = struct
    let t_of_yojson = function
      | `String "queued" -> Ok "queued"
      | `String "in_progress" -> Ok "in_progress"
      | `String "completed" -> Ok "completed"
      | `String "waiting" -> Ok "waiting"
      | `String "requested" -> Ok "requested"
      | `String "pending" -> Ok "pending"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Steps = struct
    module Items = struct
      module Primary = struct
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
