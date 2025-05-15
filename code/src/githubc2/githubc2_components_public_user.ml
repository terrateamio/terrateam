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
  bio : string option;
  blog : string option;
  collaborators : int option; [@default None]
  company : string option;
  created_at : string;
  disk_usage : int option; [@default None]
  email : string option;
  events_url : string;
  followers : int;
  followers_url : string;
  following : int;
  following_url : string;
  gists_url : string;
  gravatar_id : string option;
  hireable : bool option;
  html_url : string;
  id : int64;
  location : string option;
  login : string;
  name : string option;
  node_id : string;
  notification_email : string option; [@default None]
  organizations_url : string;
  owned_private_repos : int option; [@default None]
  plan : Plan.t option; [@default None]
  private_gists : int option; [@default None]
  public_gists : int;
  public_repos : int;
  received_events_url : string;
  repos_url : string;
  site_admin : bool;
  starred_url : string;
  subscriptions_url : string;
  total_private_repos : int option; [@default None]
  twitter_username : string option; [@default None]
  type_ : string; [@key "type"]
  updated_at : string;
  url : string;
  user_view_type : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
