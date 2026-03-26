module Action = struct
  let t_of_yojson = function
    | `String "synchronize" -> Ok `Synchronize
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Synchronize -> `String "synchronize"

  type t = ([ `Synchronize ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  after : string;
  before : string;
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  number : int;
  organization : Terrat_github_webhooks_organization.t option; [@default None]
  pull_request : Terrat_github_webhooks_pull_request.t;
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
