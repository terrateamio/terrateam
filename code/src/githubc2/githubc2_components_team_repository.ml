module Primary = struct
  module Permissions = struct
    module Primary = struct
      type t = {
        admin : bool;
        maintain : bool option; [@default None]
        pull : bool;
        push : bool;
        triage : bool option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Topics = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    allow_auto_merge : bool; [@default false]
    allow_forking : bool; [@default false]
    allow_merge_commit : bool; [@default true]
    allow_rebase_merge : bool; [@default true]
    allow_squash_merge : bool; [@default true]
    archive_url : string;
    archived : bool; [@default false]
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
    created_at : string option;
    default_branch : string;
    delete_branch_on_merge : bool; [@default false]
    deployments_url : string;
    description : string option;
    disabled : bool;
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
    has_downloads : bool; [@default true]
    has_issues : bool; [@default true]
    has_pages : bool;
    has_projects : bool; [@default true]
    has_wiki : bool; [@default true]
    homepage : string option;
    hooks_url : string;
    html_url : string;
    id : int;
    is_template : bool; [@default false]
    issue_comment_url : string;
    issue_events_url : string;
    issues_url : string;
    keys_url : string;
    labels_url : string;
    language : string option;
    languages_url : string;
    license : Githubc2_components_nullable_license_simple.t option;
    master_branch : string option; [@default None]
    merges_url : string;
    milestones_url : string;
    mirror_url : string option;
    name : string;
    network_count : int option; [@default None]
    node_id : string;
    notifications_url : string;
    open_issues : int;
    open_issues_count : int;
    owner : Githubc2_components_nullable_simple_user.t option;
    permissions : Permissions.t option; [@default None]
    private_ : bool; [@default false] [@key "private"]
    pulls_url : string;
    pushed_at : string option;
    releases_url : string;
    size : int;
    ssh_url : string;
    stargazers_count : int;
    stargazers_url : string;
    statuses_url : string;
    subscribers_count : int option; [@default None]
    subscribers_url : string;
    subscription_url : string;
    svn_url : string;
    tags_url : string;
    teams_url : string;
    temp_clone_token : string option; [@default None]
    template_repository : Githubc2_components_nullable_repository.t option; [@default None]
    topics : Topics.t option; [@default None]
    trees_url : string;
    updated_at : string option;
    url : string;
    visibility : string; [@default "public"]
    watchers : int;
    watchers_count : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
