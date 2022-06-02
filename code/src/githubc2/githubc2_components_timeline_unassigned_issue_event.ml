module Primary = struct
  type t = {
    actor : Githubc2_components_simple_user.t;
    assignee : Githubc2_components_simple_user.t;
    commit_id : string option;
    commit_url : string option;
    created_at : string;
    event : string;
    id : int;
    node_id : string;
    performed_via_github_app : Githubc2_components_nullable_integration.t option;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
