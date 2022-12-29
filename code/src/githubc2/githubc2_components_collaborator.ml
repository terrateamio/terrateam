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
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    avatar_url : string;
    email : string option; [@default None]
    events_url : string;
    followers_url : string;
    following_url : string;
    gists_url : string;
    gravatar_id : string option;
    html_url : string;
    id : int;
    login : string;
    name : string option; [@default None]
    node_id : string;
    organizations_url : string;
    permissions : Permissions.t option; [@default None]
    received_events_url : string;
    repos_url : string;
    role_name : string;
    site_admin : bool;
    starred_url : string;
    subscriptions_url : string;
    type_ : string; [@key "type"]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
