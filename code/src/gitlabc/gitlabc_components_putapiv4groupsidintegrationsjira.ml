module Primary = struct
  module Project_keys = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    api_url : string option; [@default None]
    commit_events : bool option; [@default None]
    issues_enabled : string option; [@default None]
    jira_auth_type : int option; [@default None]
    jira_issue_prefix : string option; [@default None]
    jira_issue_regex : string option; [@default None]
    jira_issue_transition_id : string option; [@default None]
    merge_requests_events : bool option; [@default None]
    password : string;
    project_keys : Project_keys.t option; [@default None]
    url : string;
    use_inherited_settings : bool option; [@default None]
    username : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
