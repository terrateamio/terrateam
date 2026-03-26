module Action = struct
  let t_of_yojson = function
    | `String "requested" -> Ok `Requested
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Requested -> `String "requested"

  type t = ([ `Requested ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  organization : Terrat_github_webhooks_organization.t option; [@default None]
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
  workflow : Terrat_github_webhooks_workflow.t;
  workflow_run : Terrat_github_webhooks_workflow_run.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
