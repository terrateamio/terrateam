module Action = struct
  let t_of_yojson = function
    | `String "auto_merge_enabled" -> Ok `Auto_merge_enabled
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Auto_merge_enabled -> `String "auto_merge_enabled"

  type t = ([ `Auto_merge_enabled ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  number : int;
  organization : Terrat_github_webhooks_organization.t option; [@default None]
  pull_request : Terrat_github_webhooks_pull_request.t;
  reason : string option; [@default None]
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
