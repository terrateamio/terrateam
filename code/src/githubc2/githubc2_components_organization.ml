module Primary = struct
  module Plan = struct
    module Primary = struct
      type t = {
        filled_seats : int option; [@default None]
        name : string option; [@default None]
        private_repos : int option; [@default None]
        seats : int option; [@default None]
        space : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    avatar_url : string;
    blog : string option; [@default None]
    company : string option; [@default None]
    created_at : string;
    description : string option;
    email : string option; [@default None]
    events_url : string;
    followers : int;
    following : int;
    has_organization_projects : bool;
    has_repository_projects : bool;
    hooks_url : string;
    html_url : string;
    id : int;
    is_verified : bool option; [@default None]
    issues_url : string;
    location : string option; [@default None]
    login : string;
    members_url : string;
    name : string option; [@default None]
    node_id : string;
    plan : Plan.t option; [@default None]
    public_gists : int;
    public_members_url : string;
    public_repos : int;
    repos_url : string;
    type_ : string; [@key "type"]
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
