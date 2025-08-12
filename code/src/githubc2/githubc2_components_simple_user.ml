module Primary = struct
  type t = {
    avatar_url : string;
    email : string option; [@default None]
    events_url : string;
    followers_url : string;
    following_url : string;
    gists_url : string;
    gravatar_id : string option;
    html_url : string;
    id : int64;
    login : string;
    name : string option; [@default None]
    node_id : string;
    organizations_url : string;
    received_events_url : string;
    repos_url : string;
    site_admin : bool;
    starred_at : string option; [@default None]
    starred_url : string;
    subscriptions_url : string;
    type_ : string; [@key "type"]
    url : string;
    user_view_type : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
