module Primary = struct
  module Labels = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Status_ = struct
    let t_of_yojson = function
      | `String "queued" -> Ok "queued"
      | `String "in_progress" -> Ok "in_progress"
      | `String "completed" -> Ok "completed"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
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
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          completed_at : string option; [@default None]
          conclusion : string option;
          name : string;
          number : int;
          started_at : string option; [@default None]
          status : Status_.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    check_run_url : string;
    completed_at : string option;
    conclusion : string option;
    head_sha : string;
    html_url : string option;
    id : int;
    labels : Labels.t;
    name : string;
    node_id : string;
    run_attempt : int option; [@default None]
    run_id : int;
    run_url : string;
    runner_group_id : int option;
    runner_group_name : string option;
    runner_id : int option;
    runner_name : string option;
    started_at : string;
    status : Status_.t;
    steps : Steps.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
