module Action = struct
  let t_of_yojson = function
    | `String "in_progress" -> Ok "in_progress"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  action : Action.t;
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  organization : Terrat_github_webhooks_organization.t option; [@default None]
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
  workflow_job : Terrat_github_webhooks_workflow_job.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show]
