module Action = struct
  let t_of_yojson = function
    | `String "completed" -> Ok "completed"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Workflow_run_ = struct
  module All_of = struct
    module Primary = struct
      module Pull_requests = struct
        module Items = struct
          module Base = struct
            type t = {
              ref_ : string; [@key "ref"]
              repo : Terrat_github_webhooks_repo_ref.t;
              sha : string;
            }
            [@@deriving yojson { strict = false; meta = true }, make, show, eq]
          end

          module Head = struct
            type t = {
              ref_ : string; [@key "ref"]
              repo : Terrat_github_webhooks_repo_ref.t;
              sha : string;
            }
            [@@deriving yojson { strict = false; meta = true }, make, show, eq]
          end

          type t = {
            base : Base.t;
            head : Head.t;
            id : float;
            number : float;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, make, show, eq]
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Referenced_workflows = struct
        module Items = struct
          include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        actor : Terrat_github_webhooks_user.t;
        artifacts_url : string;
        cancel_url : string;
        check_suite_id : int;
        check_suite_node_id : string;
        check_suite_url : string;
        conclusion : string option;
        created_at : string;
        event : string;
        head_branch : string;
        head_commit : Terrat_github_webhooks_commit_simple.t;
        head_repository : Terrat_github_webhooks_repository_lite.t;
        head_sha : string;
        html_url : string;
        id : int;
        jobs_url : string;
        logs_url : string;
        name : string;
        node_id : string;
        path : string option; [@default None]
        previous_attempt_url : string option; [@default None]
        pull_requests : Pull_requests.t;
        referenced_workflows : Referenced_workflows.t option; [@default None]
        repository : Terrat_github_webhooks_repository_lite.t;
        rerun_url : string;
        run_attempt : int;
        run_number : int;
        run_started_at : string;
        status : string;
        triggering_actor : Terrat_github_webhooks_user.t;
        updated_at : string;
        url : string;
        workflow_id : int;
        workflow_url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, make, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Pull_requests = struct
        module Items = struct
          module Base = struct
            type t = {
              ref_ : string; [@key "ref"]
              repo : Terrat_github_webhooks_repo_ref.t;
              sha : string;
            }
            [@@deriving yojson { strict = false; meta = true }, make, show, eq]
          end

          module Head = struct
            type t = {
              ref_ : string; [@key "ref"]
              repo : Terrat_github_webhooks_repo_ref.t;
              sha : string;
            }
            [@@deriving yojson { strict = false; meta = true }, make, show, eq]
          end

          type t = {
            base : Base.t;
            head : Head.t;
            id : float;
            number : float;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, make, show, eq]
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Referenced_workflows = struct
        module Items = struct
          include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        actor : Terrat_github_webhooks_user.t;
        artifacts_url : string;
        cancel_url : string;
        check_suite_id : int;
        check_suite_node_id : string;
        check_suite_url : string;
        conclusion : string option;
        created_at : string;
        event : string;
        head_branch : string;
        head_commit : Terrat_github_webhooks_commit_simple.t;
        head_repository : Terrat_github_webhooks_repository_lite.t;
        head_sha : string;
        html_url : string;
        id : int;
        jobs_url : string;
        logs_url : string;
        name : string;
        node_id : string;
        path : string option; [@default None]
        previous_attempt_url : string option; [@default None]
        pull_requests : Pull_requests.t;
        referenced_workflows : Referenced_workflows.t option; [@default None]
        repository : Terrat_github_webhooks_repository_lite.t;
        rerun_url : string;
        run_attempt : int;
        run_number : int;
        run_started_at : string;
        status : string;
        triggering_actor : Terrat_github_webhooks_user.t;
        updated_at : string;
        url : string;
        workflow_id : int;
        workflow_url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, make, show, eq]
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
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  organization : Terrat_github_webhooks_organization.t option; [@default None]
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
  workflow : Terrat_github_webhooks_workflow.t;
  workflow_run : Workflow_run_.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
