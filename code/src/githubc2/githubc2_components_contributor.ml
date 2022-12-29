module Primary = struct
  type t = {
    avatar_url : string option; [@default None]
    contributions : int;
    email : string option; [@default None]
    events_url : string option; [@default None]
    followers_url : string option; [@default None]
    following_url : string option; [@default None]
    gists_url : string option; [@default None]
    gravatar_id : string option; [@default None]
    html_url : string option; [@default None]
    id : int option; [@default None]
    login : string option; [@default None]
    name : string option; [@default None]
    node_id : string option; [@default None]
    organizations_url : string option; [@default None]
    received_events_url : string option; [@default None]
    repos_url : string option; [@default None]
    site_admin : bool option; [@default None]
    starred_url : string option; [@default None]
    subscriptions_url : string option; [@default None]
    type_ : string; [@key "type"]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
