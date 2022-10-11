module Primary = struct
  module Privacy = struct
    let t_of_yojson = function
      | `String "closed" -> Ok "closed"
      | `String "secret" -> Ok "secret"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    created_at : string;
    description : string option;
    html_url : string;
    id : int;
    ldap_dn : string option; [@default None]
    members_count : int;
    members_url : string;
    name : string;
    node_id : string;
    organization : Githubc2_components_team_organization.t;
    parent : Githubc2_components_nullable_team_simple.t option; [@default None]
    permission : string;
    privacy : Privacy.t option; [@default None]
    repos_count : int;
    repositories_url : string;
    slug : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
