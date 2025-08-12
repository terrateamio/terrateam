module Primary = struct
  module Type = struct
    let t_of_yojson = function
      | `String "Bot" -> Ok "Bot"
      | `String "User" -> Ok "User"
      | `String "Organization" -> Ok "Organization"
      | `String "Mannequin" -> Ok "Mannequin"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    avatar_url : string option; [@default None]
    deleted : bool option; [@default None]
    email : string option; [@default None]
    events_url : string option; [@default None]
    followers_url : string option; [@default None]
    following_url : string option; [@default None]
    gists_url : string option; [@default None]
    gravatar_id : string option; [@default None]
    html_url : string option; [@default None]
    id : int;
    login : string;
    name : string option; [@default None]
    node_id : string option; [@default None]
    organizations_url : string option; [@default None]
    received_events_url : string option; [@default None]
    repos_url : string option; [@default None]
    site_admin : bool option; [@default None]
    starred_url : string option; [@default None]
    subscriptions_url : string option; [@default None]
    type_ : Type.t option; [@default None] [@key "type"]
    url : string option; [@default None]
    user_view_type : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
