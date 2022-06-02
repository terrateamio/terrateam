module Primary = struct
  type t = {
    avatar_url : string;
    bio : string option; [@default None]
    blog : string option; [@default None]
    company : string option; [@default None]
    created_at : string option; [@default None]
    email : string option; [@default None]
    events_url : string;
    followers : int option; [@default None]
    followers_url : string;
    following : int option; [@default None]
    following_url : string;
    gists_url : string;
    gravatar_id : string option;
    hireable : bool option; [@default None]
    html_url : string;
    id : int;
    location : string option; [@default None]
    login : string;
    name : string option; [@default None]
    node_id : string;
    organizations_url : string;
    public_gists : int option; [@default None]
    public_repos : int option; [@default None]
    received_events_url : string;
    repos_url : string;
    score : float;
    site_admin : bool;
    starred_url : string;
    subscriptions_url : string;
    suspended_at : string option; [@default None]
    text_matches : Githubc2_components_search_result_text_matches.t option; [@default None]
    type_ : string; [@key "type"]
    updated_at : string option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
