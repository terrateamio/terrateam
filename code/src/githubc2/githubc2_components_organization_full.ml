module Primary = struct
  module Plan = struct
    module Primary = struct
      type t = {
        filled_seats : int option; [@default None]
        name : string;
        private_repos : int;
        seats : int option; [@default None]
        space : int;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    advanced_security_enabled_for_new_repositories : bool option; [@default None]
    archived_at : string option;
    avatar_url : string;
    billing_email : string option; [@default None]
    blog : string option; [@default None]
    collaborators : int option; [@default None]
    company : string option; [@default None]
    created_at : string;
    default_repository_permission : string option; [@default None]
    dependabot_alerts_enabled_for_new_repositories : bool option; [@default None]
    dependabot_security_updates_enabled_for_new_repositories : bool option; [@default None]
    dependency_graph_enabled_for_new_repositories : bool option; [@default None]
    deploy_keys_enabled_for_repositories : bool option; [@default None]
    description : string option;
    disk_usage : int option; [@default None]
    email : string option; [@default None]
    events_url : string;
    followers : int;
    following : int;
    has_organization_projects : bool;
    has_repository_projects : bool;
    hooks_url : string;
    html_url : string;
    id : int;
    is_verified : bool option; [@default None]
    issues_url : string;
    location : string option; [@default None]
    login : string;
    members_allowed_repository_creation_type : string option; [@default None]
    members_can_create_internal_repositories : bool option; [@default None]
    members_can_create_pages : bool option; [@default None]
    members_can_create_private_pages : bool option; [@default None]
    members_can_create_private_repositories : bool option; [@default None]
    members_can_create_public_pages : bool option; [@default None]
    members_can_create_public_repositories : bool option; [@default None]
    members_can_create_repositories : bool option; [@default None]
    members_can_fork_private_repositories : bool option; [@default None]
    members_url : string;
    name : string option; [@default None]
    node_id : string;
    owned_private_repos : int option; [@default None]
    plan : Plan.t option; [@default None]
    private_gists : int option; [@default None]
    public_gists : int;
    public_members_url : string;
    public_repos : int;
    repos_url : string;
    secret_scanning_enabled_for_new_repositories : bool option; [@default None]
    secret_scanning_push_protection_custom_link : string option; [@default None]
    secret_scanning_push_protection_custom_link_enabled : bool option; [@default None]
    secret_scanning_push_protection_enabled_for_new_repositories : bool option; [@default None]
    total_private_repos : int option; [@default None]
    twitter_username : string option; [@default None]
    two_factor_requirement_enabled : bool option; [@default None]
    type_ : string; [@key "type"]
    updated_at : string;
    url : string;
    web_commit_signoff_required : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
