module Created_at = struct
  module V0 = struct
    type t = int [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module V1 = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t =
    | V0 of V0.t
    | V1 of V1.t
  [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [
         (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
         (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
       ])

  let to_yojson = function
    | V0 v -> V0.to_yojson v
    | V1 v -> V1.to_yojson v
end

module Permissions = struct
  module Additional = struct
    type t = bool [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

module Pushed_at = struct
  module V0 = struct
    type t = int [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module V1 = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t =
    | V0 of V0.t
    | V1 of V1.t
  [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [
         (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
         (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
       ])

  let to_yojson = function
    | V0 v -> V0.to_yojson v
    | V1 v -> V1.to_yojson v
end

module Topics = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  allow_auto_merge : bool; [@default false]
  allow_forking : bool option; [@default None]
  allow_merge_commit : bool; [@default true]
  allow_rebase_merge : bool; [@default true]
  allow_squash_merge : bool; [@default true]
  allow_update_branch : bool option; [@default None]
  archive_url : string;
  archived : bool;
  assignees_url : string;
  blobs_url : string;
  branches_url : string;
  clone_url : string;
  collaborators_url : string;
  comments_url : string;
  commits_url : string;
  compare_url : string;
  contents_url : string;
  contributors_url : string;
  created_at : Created_at.t;
  default_branch : string;
  delete_branch_on_merge : bool; [@default false]
  deployments_url : string;
  description : string option;
  disabled : bool option; [@default None]
  downloads_url : string;
  events_url : string;
  fork : bool;
  forks : int;
  forks_count : int;
  forks_url : string;
  full_name : string;
  git_commits_url : string;
  git_refs_url : string;
  git_tags_url : string;
  git_url : string;
  has_downloads : bool;
  has_issues : bool;
  has_pages : bool;
  has_projects : bool;
  has_wiki : bool;
  homepage : string option;
  hooks_url : string;
  html_url : string;
  id : int;
  is_template : bool;
  issue_comment_url : string;
  issue_events_url : string;
  issues_url : string;
  keys_url : string;
  labels_url : string;
  language : string option;
  languages_url : string;
  license : Terrat_github_webhooks_license.t option; [@default None]
  master_branch : string option; [@default None]
  merges_url : string;
  milestones_url : string;
  mirror_url : string option;
  name : string;
  node_id : string;
  notifications_url : string;
  open_issues : int;
  open_issues_count : int;
  organization : string option; [@default None]
  owner : Terrat_github_webhooks_user.t;
  permissions : Permissions.t option; [@default None]
  private_ : bool; [@key "private"]
  public : bool option; [@default None]
  pulls_url : string;
  pushed_at : Pushed_at.t option; [@default None]
  releases_url : string;
  size : int;
  ssh_url : string;
  stargazers : int option; [@default None]
  stargazers_count : int;
  stargazers_url : string;
  statuses_url : string;
  subscribers_url : string;
  subscription_url : string;
  svn_url : string;
  tags_url : string;
  teams_url : string;
  topics : Topics.t;
  trees_url : string;
  updated_at : string;
  url : string;
  use_squash_pr_title_as_default : bool option; [@default None]
  visibility : string;
  watchers : int;
  watchers_count : int;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
