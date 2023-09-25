module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "in_progress" -> Ok "in_progress"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Workflow_job = struct
    module All_of = struct
      module Primary = struct
        module Conclusion = struct
          let t_of_yojson = function
            | `String "success" -> Ok "success"
            | `String "failure" -> Ok "failure"
            | `String "cancelled" -> Ok "cancelled"
            | `String "neutral" -> Ok "neutral"
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
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Steps = struct
          module Items = struct
            module Primary = struct
              module Conclusion = struct
                let t_of_yojson = function
                  | `String "failure" -> Ok "failure"
                  | `String "skipped" -> Ok "skipped"
                  | `String "success" -> Ok "success"
                  | `String "cancelled" -> Ok "cancelled"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Status_ = struct
                let t_of_yojson = function
                  | `String "in_progress" -> Ok "in_progress"
                  | `String "completed" -> Ok "completed"
                  | `String "queued" -> Ok "queued"
                  | `String "pending" -> Ok "pending"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              type t = {
                completed_at : string option;
                conclusion : Conclusion.t option;
                name : string;
                number : int;
                started_at : string option;
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
          completed_at : string option;
          conclusion : Conclusion.t option;
          created_at : string;
          head_branch : string option;
          head_sha : string;
          html_url : string;
          id : int;
          labels : Labels.t;
          name : string;
          node_id : string;
          run_attempt : int;
          run_id : float;
          run_url : string;
          runner_group_id : int option;
          runner_group_name : string option;
          runner_id : int option;
          runner_name : string option;
          started_at : string;
          status : Status_.t;
          steps : Steps.t;
          url : string;
          workflow_name : string option;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module T = struct
      module Primary = struct
        module Conclusion = struct
          let t_of_yojson = function
            | `String "success" -> Ok "success"
            | `String "failure" -> Ok "failure"
            | `String "cancelled" -> Ok "cancelled"
            | `String "neutral" -> Ok "neutral"
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
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Steps = struct
          module Items = struct
            module Primary = struct
              module Conclusion = struct
                let t_of_yojson = function
                  | `String "failure" -> Ok "failure"
                  | `String "skipped" -> Ok "skipped"
                  | `String "success" -> Ok "success"
                  | `String "cancelled" -> Ok "cancelled"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Status_ = struct
                let t_of_yojson = function
                  | `String "in_progress" -> Ok "in_progress"
                  | `String "completed" -> Ok "completed"
                  | `String "queued" -> Ok "queued"
                  | `String "pending" -> Ok "pending"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              type t = {
                completed_at : string option;
                conclusion : Conclusion.t option;
                name : string;
                number : int;
                started_at : string option;
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
          completed_at : string option;
          conclusion : Conclusion.t option;
          created_at : string;
          head_branch : string option;
          head_sha : string;
          html_url : string;
          id : int;
          labels : Labels.t;
          name : string;
          node_id : string;
          run_attempt : int;
          run_id : float;
          run_url : string;
          runner_group_id : int option;
          runner_group_name : string option;
          runner_id : int option;
          runner_name : string option;
          started_at : string;
          status : Status_.t;
          steps : Steps.t;
          url : string;
          workflow_name : string option;
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
    sender : Githubc2_components_simple_user_webhooks.t;
    workflow_job : Workflow_job.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
