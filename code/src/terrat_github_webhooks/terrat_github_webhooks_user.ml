module Type = struct
  let t_of_yojson = function
    | `String "Bot" -> Ok "Bot"
    | `String "User" -> Ok "User"
    | `String "Organization" -> Ok "Organization"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  avatar_url : string;
  email : string option; [@default None]
  events_url : string;
  followers_url : string;
  following_url : string;
  gists_url : string;
  gravatar_id : string;
  html_url : string;
  id : int;
  login : string;
  name : string option; [@default None]
  node_id : string;
  organizations_url : string;
  received_events_url : string;
  repos_url : string;
  site_admin : bool;
  starred_url : string;
  subscriptions_url : string;
  type_ : Type.t; [@key "type"]
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
