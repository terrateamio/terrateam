module Primary = struct
  type t = {
    archive_url : string;
    assignees_url : string;
    blobs_url : string;
    branches_url : string;
    collaborators_url : string;
    comments_url : string;
    commits_url : string;
    compare_url : string;
    contents_url : string;
    contributors_url : string;
    deployments_url : string;
    description : string option;
    downloads_url : string;
    events_url : string;
    fork : bool;
    forks_url : string;
    full_name : string;
    git_commits_url : string;
    git_refs_url : string;
    git_tags_url : string;
    hooks_url : string;
    html_url : string;
    id : int64;
    issue_comment_url : string;
    issue_events_url : string;
    issues_url : string;
    keys_url : string;
    labels_url : string;
    languages_url : string;
    merges_url : string;
    milestones_url : string;
    name : string;
    node_id : string;
    notifications_url : string;
    owner : Githubc2_components_simple_user.t;
    private_ : bool; [@key "private"]
    pulls_url : string;
    releases_url : string;
    stargazers_url : string;
    statuses_url : string;
    subscribers_url : string;
    subscription_url : string;
    tags_url : string;
    teams_url : string;
    trees_url : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
