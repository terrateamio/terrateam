module Primary = struct
  module Assignment = struct
    let t_of_yojson = function
      | `String "direct" -> Ok `Direct
      | `String "indirect" -> Ok `Indirect
      | `String "mixed" -> Ok `Mixed
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Direct -> `String "direct"
      | `Indirect -> `String "indirect"
      | `Mixed -> `String "mixed"

    type t =
      ([ `Direct
       | `Indirect
       | `Mixed
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Inherited_from = struct
    type t = Githubc2_components_team_simple.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    assignment : Assignment.t option; [@default None]
    avatar_url : string;
    email : string option; [@default None]
    events_url : string;
    followers_url : string;
    following_url : string;
    gists_url : string;
    gravatar_id : string option; [@default None]
    html_url : string;
    id : int;
    inherited_from : Inherited_from.t option; [@default None]
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
