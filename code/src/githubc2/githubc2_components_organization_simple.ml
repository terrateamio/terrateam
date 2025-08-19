module Primary = struct
  type t = {
    avatar_url : string;
    description : string option; [@default None]
    events_url : string;
    hooks_url : string;
    id : int;
    issues_url : string;
    login : string;
    members_url : string;
    node_id : string;
    public_members_url : string;
    repos_url : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
