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

  module Security_and_analysis = struct
    module Primary = struct
      module Advanced_security = struct
        module Primary = struct
          module Status_ = struct
            let t_of_yojson = function
              | `String "enabled" -> Ok "enabled"
              | `String "disabled" -> Ok "disabled"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = { status : Status_.t option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Secret_scanning = struct
        module Primary = struct
          module Status_ = struct
            let t_of_yojson = function
              | `String "enabled" -> Ok "enabled"
              | `String "disabled" -> Ok "disabled"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = { status : Status_.t option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        advanced_security : Advanced_security.t option; [@default None]
        secret_scanning : Secret_scanning.t option; [@default None]
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
    allow_forking : bool option; [@default None]
    allow_merge_commit : bool option; [@default None]
    allow_rebase_merge : bool option; [@default None]
    allow_squash_merge : bool option; [@default None]
    anonymous_access_enabled : bool; [@default true]
    archive_url : string;
    archived : bool;
    assignees_url : string;
    blobs_url : string;
    branches_url : string;
    clone_url : string;
    code_of_conduct : Githubc2_components_code_of_conduct_simple.t option; [@default None]
    collaborators_url : string;
    comments_url : string;
    commits_url : string;
    compare_url : string;
    contents_url : string;
    contributors_url : string;
    created_at : string;
    default_branch : string;
    delete_branch_on_merge : bool option; [@default None]
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
    has_downloads : bool;
    has_issues : bool;
    has_pages : bool;
    has_projects : bool;
    has_wiki : bool;
    homepage : string option;
    hooks_url : string;
    html_url : string;
    id : int;
    is_template : bool option; [@default None]
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
    network_count : int;
    node_id : string;
    notifications_url : string;
    open_issues : int;
    open_issues_count : int;
    organization : Githubc2_components_nullable_simple_user.t option; [@default None]
    owner : Githubc2_components_simple_user.t;
    parent : Githubc2_components_repository.t option; [@default None]
    permissions : Permissions.t option; [@default None]
    private_ : bool; [@key "private"]
    pulls_url : string;
    pushed_at : string;
    releases_url : string;
    security_and_analysis : Security_and_analysis.t option; [@default None]
    size : int;
    source : Githubc2_components_repository.t option; [@default None]
    ssh_url : string;
    stargazers_count : int;
    stargazers_url : string;
    statuses_url : string;
    subscribers_count : int;
    subscribers_url : string;
    subscription_url : string;
    svn_url : string;
    tags_url : string;
    teams_url : string;
    temp_clone_token : string option; [@default None]
    template_repository : Githubc2_components_nullable_repository.t option; [@default None]
    topics : Topics.t option; [@default None]
    trees_url : string;
    updated_at : string;
    url : string;
    visibility : string option; [@default None]
    watchers : int;
    watchers_count : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
