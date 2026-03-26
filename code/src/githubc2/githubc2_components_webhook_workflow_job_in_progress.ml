module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "in_progress" -> Ok `In_progress
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `In_progress -> `String "in_progress"

    type t = ([ `In_progress ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Workflow_job = struct
    module All_of = struct
      module Primary = struct
        module Conclusion = struct
          let t_of_yojson = function
            | `String "cancelled" -> Ok `Cancelled
            | `String "failure" -> Ok `Failure
            | `String "neutral" -> Ok `Neutral
            | `String "success" -> Ok `Success
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          let t_to_yojson = function
            | `Cancelled -> `String "cancelled"
            | `Failure -> `String "failure"
            | `Neutral -> `String "neutral"
            | `Success -> `String "success"

          type t =
            ([ `Cancelled
             | `Failure
             | `Neutral
             | `Success
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

        module Steps = struct
          module Items = struct
            module Primary = struct
              module Conclusion = struct
                let t_of_yojson = function
                  | `String "cancelled" -> Ok `Cancelled
                  | `String "failure" -> Ok `Failure
                  | `String "skipped" -> Ok `Skipped
                  | `String "success" -> Ok `Success
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Cancelled -> `String "cancelled"
                  | `Failure -> `String "failure"
                  | `Skipped -> `String "skipped"
                  | `Success -> `String "success"

                type t =
                  ([ `Cancelled
                   | `Failure
                   | `Skipped
                   | `Success
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
                completed_at : string option; [@default None]
                conclusion : Conclusion.t option; [@default None]
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
          html_url : string;
          id : int;
          labels : Labels.t;
          name : string;
          node_id : string;
          run_attempt : int;
          run_id : float;
          run_url : string;
          runner_group_id : int option; [@default None]
          runner_group_name : string option; [@default None]
          runner_id : int option; [@default None]
          runner_name : string option; [@default None]
          started_at : string;
          status : Status_.t;
          steps : Steps.t;
          url : string;
          workflow_name : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module T = struct
      module Primary = struct
        module Conclusion = struct
          let t_of_yojson = function
            | `String "cancelled" -> Ok `Cancelled
            | `String "failure" -> Ok `Failure
            | `String "neutral" -> Ok `Neutral
            | `String "success" -> Ok `Success
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          let t_to_yojson = function
            | `Cancelled -> `String "cancelled"
            | `Failure -> `String "failure"
            | `Neutral -> `String "neutral"
            | `Success -> `String "success"

          type t =
            ([ `Cancelled
             | `Failure
             | `Neutral
             | `Success
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

        module Steps = struct
          module Items = struct
            module Primary = struct
              module Conclusion = struct
                let t_of_yojson = function
                  | `String "cancelled" -> Ok `Cancelled
                  | `String "failure" -> Ok `Failure
                  | `String "skipped" -> Ok `Skipped
                  | `String "success" -> Ok `Success
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Cancelled -> `String "cancelled"
                  | `Failure -> `String "failure"
                  | `Skipped -> `String "skipped"
                  | `Success -> `String "success"

                type t =
                  ([ `Cancelled
                   | `Failure
                   | `Skipped
                   | `Success
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
                completed_at : string option; [@default None]
                conclusion : Conclusion.t option; [@default None]
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
          html_url : string;
          id : int;
          labels : Labels.t;
          name : string;
          node_id : string;
          run_attempt : int;
          run_id : float;
          run_url : string;
          runner_group_id : int option; [@default None]
          runner_group_name : string option; [@default None]
          runner_id : int option; [@default None]
          runner_name : string option; [@default None]
          started_at : string;
          status : Status_.t;
          steps : Steps.t;
          url : string;
          workflow_name : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

    let of_yojson json =
      let open CCResult in
      flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
  end

  type t = {
    action : Action.t;
    deployment : Githubc2_components_deployment.t option; [@default None]
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t;
    workflow_job : Workflow_job.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
