type t = {
  action : string;
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  organization : Terrat_github_webhooks_organization.t option; [@default None]
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
  workflow_job : Terrat_github_webhooks_workflow_job.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
