module Commits = struct
  type t = Terrat_github_webhooks_commit.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Head_commit = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  after : string;
  base_ref : string option; [@default None]
  before : string;
  commits : Commits.t;
  compare : string;
  created : bool;
  deleted : bool;
  forced : bool;
  head_commit : Head_commit.t option; [@default None]
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  organization : Terrat_github_webhooks_organization.t option; [@default None]
  pusher : Terrat_github_webhooks_committer.t;
  ref_ : string; [@key "ref"]
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
