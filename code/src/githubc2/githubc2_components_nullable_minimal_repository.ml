module Primary = struct
  module License_ = struct
    module Primary = struct
      type t = {
        key : string option; [@default None]
        name : string option; [@default None]
        node_id : string option; [@default None]
        spdx_id : string option; [@default None]
        url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Permissions = struct
    module Primary = struct
      type t = {
        admin : bool option; [@default None]
        maintain : bool option; [@default None]
        pull : bool option; [@default None]
        push : bool option; [@default None]
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
    allow_forking : bool option; [@default None]
    archive_url : string;
    archived : bool option; [@default None]
    assignees_url : string;
    blobs_url : string;
    branches_url : string;
    clone_url : string option; [@default None]
    code_of_conduct : Githubc2_components_code_of_conduct.t option; [@default None]
    collaborators_url : string;
    comments_url : string;
    commits_url : string;
    compare_url : string;
    contents_url : string;
    contributors_url : string;
    created_at : string option; [@default None]
    default_branch : string option; [@default None]
    delete_branch_on_merge : bool option; [@default None]
    deployments_url : string;
    description : string option;
    disabled : bool option; [@default None]
    downloads_url : string;
    events_url : string;
    fork : bool;
    forks : int option; [@default None]
    forks_count : int option; [@default None]
    forks_url : string;
    full_name : string;
    git_commits_url : string;
    git_refs_url : string;
    git_tags_url : string;
    git_url : string option; [@default None]
    has_downloads : bool option; [@default None]
    has_issues : bool option; [@default None]
    has_pages : bool option; [@default None]
    has_projects : bool option; [@default None]
    has_wiki : bool option; [@default None]
    homepage : string option; [@default None]
    hooks_url : string;
    html_url : string;
    id : int;
    is_template : bool option; [@default None]
    issue_comment_url : string;
    issue_events_url : string;
    issues_url : string;
    keys_url : string;
    labels_url : string;
    language : string option; [@default None]
    languages_url : string;
    license : License_.t option; [@default None]
    merges_url : string;
    milestones_url : string;
    mirror_url : string option; [@default None]
    name : string;
    network_count : int option; [@default None]
    node_id : string;
    notifications_url : string;
    open_issues : int option; [@default None]
    open_issues_count : int option; [@default None]
    owner : Githubc2_components_simple_user.t;
    permissions : Permissions.t option; [@default None]
    private_ : bool; [@key "private"]
    pulls_url : string;
    pushed_at : string option; [@default None]
    releases_url : string;
    role_name : string option; [@default None]
    size : int option; [@default None]
    ssh_url : string option; [@default None]
    stargazers_count : int option; [@default None]
    stargazers_url : string;
    statuses_url : string;
    subscribers_count : int option; [@default None]
    subscribers_url : string;
    subscription_url : string;
    svn_url : string option; [@default None]
    tags_url : string;
    teams_url : string;
    temp_clone_token : string option; [@default None]
    template_repository : Githubc2_components_nullable_repository.t option; [@default None]
    topics : Topics.t option; [@default None]
    trees_url : string;
    updated_at : string option; [@default None]
    url : string;
    visibility : string option; [@default None]
    watchers : int option; [@default None]
    watchers_count : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
