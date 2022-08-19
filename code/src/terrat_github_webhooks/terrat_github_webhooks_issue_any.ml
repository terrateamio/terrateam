type t = {
  action : string;
  installation : Terrat_github_webhooks_installation_lite.t;
  issue : Terrat_github_webhooks_issue.t;
  organization : Terrat_github_webhooks_organization.t;
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show]
