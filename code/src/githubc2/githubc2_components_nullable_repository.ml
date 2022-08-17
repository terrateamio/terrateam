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

  module Template_repository = struct
    module Primary = struct
      module Owner = struct
        module Primary = struct
          type t = {
            avatar_url : string option; [@default None]
            events_url : string option; [@default None]
            followers_url : string option; [@default None]
            following_url : string option; [@default None]
            gists_url : string option; [@default None]
            gravatar_id : string option; [@default None]
            html_url : string option; [@default None]
            id : int option; [@default None]
            login : string option; [@default None]
            node_id : string option; [@default None]
            organizations_url : string option; [@default None]
            received_events_url : string option; [@default None]
            repos_url : string option; [@default None]
            site_admin : bool option; [@default None]
            starred_url : string option; [@default None]
            subscriptions_url : string option; [@default None]
            type_ : string option; [@default None] [@key "type"]
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
        allow_auto_merge : bool option; [@default None]
        allow_merge_commit : bool option; [@default None]
        allow_rebase_merge : bool option; [@default None]
        allow_squash_merge : bool option; [@default None]
        allow_update_branch : bool option; [@default None]
        archive_url : string option; [@default None]
        archived : bool option; [@default None]
        assignees_url : string option; [@default None]
        blobs_url : string option; [@default None]
        branches_url : string option; [@default None]
        clone_url : string option; [@default None]
        collaborators_url : string option; [@default None]
        comments_url : string option; [@default None]
        commits_url : string option; [@default None]
        compare_url : string option; [@default None]
        contents_url : string option; [@default None]
        contributors_url : string option; [@default None]
        created_at : string option; [@default None]
        default_branch : string option; [@default None]
        delete_branch_on_merge : bool option; [@default None]
        deployments_url : string option; [@default None]
        description : string option; [@default None]
        disabled : bool option; [@default None]
        downloads_url : string option; [@default None]
        events_url : string option; [@default None]
        fork : bool option; [@default None]
        forks_count : int option; [@default None]
        forks_url : string option; [@default None]
        full_name : string option; [@default None]
        git_commits_url : string option; [@default None]
        git_refs_url : string option; [@default None]
        git_tags_url : string option; [@default None]
        git_url : string option; [@default None]
        has_downloads : bool option; [@default None]
        has_issues : bool option; [@default None]
        has_pages : bool option; [@default None]
        has_projects : bool option; [@default None]
        has_wiki : bool option; [@default None]
        homepage : string option; [@default None]
        hooks_url : string option; [@default None]
        html_url : string option; [@default None]
        id : int option; [@default None]
        is_template : bool option; [@default None]
        issue_comment_url : string option; [@default None]
        issue_events_url : string option; [@default None]
        issues_url : string option; [@default None]
        keys_url : string option; [@default None]
        labels_url : string option; [@default None]
        language : string option; [@default None]
        languages_url : string option; [@default None]
        merges_url : string option; [@default None]
        milestones_url : string option; [@default None]
        mirror_url : string option; [@default None]
        name : string option; [@default None]
        network_count : int option; [@default None]
        node_id : string option; [@default None]
        notifications_url : string option; [@default None]
        open_issues_count : int option; [@default None]
        owner : Owner.t option; [@default None]
        permissions : Permissions.t option; [@default None]
        private_ : bool option; [@default None] [@key "private"]
        pulls_url : string option; [@default None]
        pushed_at : string option; [@default None]
        releases_url : string option; [@default None]
        size : int option; [@default None]
        ssh_url : string option; [@default None]
        stargazers_count : int option; [@default None]
        stargazers_url : string option; [@default None]
        statuses_url : string option; [@default None]
        subscribers_count : int option; [@default None]
        subscribers_url : string option; [@default None]
        subscription_url : string option; [@default None]
        svn_url : string option; [@default None]
        tags_url : string option; [@default None]
        teams_url : string option; [@default None]
        temp_clone_token : string option; [@default None]
        topics : Topics.t option; [@default None]
        trees_url : string option; [@default None]
        updated_at : string option; [@default None]
        url : string option; [@default None]
        use_squash_pr_title_as_default : bool option; [@default None]
        visibility : string option; [@default None]
        watchers_count : int option; [@default None]
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
    allow_forking : bool option; [@default None]
    allow_merge_commit : bool; [@default true]
    allow_rebase_merge : bool; [@default true]
    allow_squash_merge : bool; [@default true]
    allow_update_branch : bool; [@default false]
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
    organization : Githubc2_components_nullable_simple_user.t option; [@default None]
    owner : Githubc2_components_simple_user.t;
    permissions : Permissions.t option; [@default None]
    private_ : bool; [@default false] [@key "private"]
    pulls_url : string;
    pushed_at : string option;
    releases_url : string;
    size : int;
    ssh_url : string;
    stargazers_count : int;
    stargazers_url : string;
    starred_at : string option; [@default None]
    statuses_url : string;
    subscribers_count : int option; [@default None]
    subscribers_url : string;
    subscription_url : string;
    svn_url : string;
    tags_url : string;
    teams_url : string;
    temp_clone_token : string option; [@default None]
    template_repository : Template_repository.t option; [@default None]
    topics : Topics.t option; [@default None]
    trees_url : string;
    updated_at : string option;
    url : string;
    use_squash_pr_title_as_default : bool; [@default false]
    visibility : string; [@default "public"]
    watchers : int;
    watchers_count : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
