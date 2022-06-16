module Action = struct
  let t_of_yojson = function
    | `String "in_progress" -> Ok "in_progress"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Workflow_job_ = struct
  module All_of = struct
    module Primary = struct
      module Labels = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Status = struct
        let t_of_yojson = function
          | `String "in_progress" -> Ok "in_progress"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Steps = struct
        type t = Terrat_github_webhooks_workflow_step.t list
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        check_run_url : string;
        completed_at : string option;
        conclusion : string option;
        head_sha : string;
        html_url : string;
        id : int;
        labels : Labels.t;
        name : string;
        node_id : string;
        run_attempt : int;
        run_id : int;
        run_url : string;
        runner_group_id : int option;
        runner_group_name : string option;
        runner_id : int option;
        runner_name : string option;
        started_at : string;
        status : Status.t;
        steps : Steps.t;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, make, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Labels = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Status = struct
        let t_of_yojson = function
          | `String "in_progress" -> Ok "in_progress"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Steps = struct
        type t = Terrat_github_webhooks_workflow_step.t list
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        check_run_url : string;
        completed_at : string option;
        conclusion : string option;
        head_sha : string;
        html_url : string;
        id : int;
        labels : Labels.t;
        name : string;
        node_id : string;
        run_attempt : int;
        run_id : int;
        run_url : string;
        runner_group_id : int option;
        runner_group_name : string option;
        runner_id : int option;
        runner_name : string option;
        started_at : string;
        status : Status.t;
        steps : Steps.t;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, make, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show]

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
  workflow_job : Workflow_job_.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show]
