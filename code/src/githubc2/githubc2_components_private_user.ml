module Primary = struct
  module Plan = struct
    module Primary = struct
      type t = {
        collaborators : int;
        name : string;
        private_repos : int;
        space : int;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    avatar_url : string;
    bio : string option; [@default None]
    blog : string option; [@default None]
    business_plus : bool option; [@default None]
    collaborators : int;
    company : string option; [@default None]
    created_at : string;
    disk_usage : int;
    email : string option; [@default None]
    events_url : string;
    followers : int;
    followers_url : string;
    following : int;
    following_url : string;
    gists_url : string;
    gravatar_id : string option; [@default None]
    hireable : bool option; [@default None]
    html_url : string;
    id : int64;
    ldap_dn : string option; [@default None]
    location : string option; [@default None]
    login : string;
    name : string option; [@default None]
    node_id : string;
    notification_email : string option; [@default None]
    organizations_url : string;
    owned_private_repos : int;
    plan : Plan.t option; [@default None]
    private_gists : int;
    public_gists : int;
    public_repos : int;
    received_events_url : string;
    repos_url : string;
    site_admin : bool;
    starred_url : string;
    subscriptions_url : string;
    total_private_repos : int;
    twitter_username : string option; [@default None]
    two_factor_authentication : bool;
    type_ : string; [@key "type"]
    updated_at : string;
    url : string;
    user_view_type : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
