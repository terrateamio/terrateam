module Primary = struct
  type t = {
    authorizations_url : string;
    code_search_url : string;
    commit_search_url : string;
    current_user_authorizations_html_url : string;
    current_user_repositories_url : string;
    current_user_url : string;
    emails_url : string;
    emojis_url : string;
    events_url : string;
    feeds_url : string;
    followers_url : string;
    following_url : string;
    gists_url : string;
    hub_url : string option; [@default None]
    issue_search_url : string;
    issues_url : string;
    keys_url : string;
    label_search_url : string;
    notifications_url : string;
    organization_repositories_url : string;
    organization_teams_url : string;
    organization_url : string;
    public_gists_url : string;
    rate_limit_url : string;
    repository_search_url : string;
    repository_url : string;
    starred_gists_url : string;
    starred_url : string;
    topic_search_url : string option; [@default None]
    user_organizations_url : string;
    user_repositories_url : string;
    user_search_url : string;
    user_url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
