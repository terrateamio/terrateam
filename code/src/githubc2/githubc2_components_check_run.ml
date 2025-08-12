module Primary = struct
  module Check_suite_ = struct
    module Primary = struct
      type t = { id : int } [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

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

  module Output = struct
    module Primary = struct
      type t = {
        annotations_count : int;
        annotations_url : string;
        summary : string option;
        text : string option;
        title : string option;
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

  type t = {
    app : Githubc2_components_nullable_integration.t option;
    check_suite : Check_suite_.t option;
    completed_at : string option;
    conclusion : Conclusion.t option;
    deployment : Githubc2_components_deployment_simple.t option; [@default None]
    details_url : string option;
    external_id : string option;
    head_sha : string;
    html_url : string option;
    id : int64;
    name : string;
    node_id : string;
    output : Output.t;
    pull_requests : Pull_requests.t;
    started_at : string option;
    status : Status_.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
