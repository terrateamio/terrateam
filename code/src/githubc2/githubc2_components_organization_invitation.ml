module Primary = struct
  type t = {
    created_at : string;
    email : string option;
    failed_at : string option; [@default None]
    failed_reason : string option; [@default None]
    id : int64;
    invitation_source : string option; [@default None]
    invitation_teams_url : string;
    inviter : Githubc2_components_simple_user.t;
    login : string option;
    node_id : string;
    role : string;
    team_count : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
