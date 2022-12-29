module Primary = struct
  type t = {
    author_association : Githubc2_components_author_association.t;
    body : string;
    commit_id : string;
    created_at : string;
    html_url : string;
    id : int;
    line : int option;
    node_id : string;
    path : string option;
    position : int option;
    reactions : Githubc2_components_reaction_rollup.t option; [@default None]
    updated_at : string;
    url : string;
    user : Githubc2_components_nullable_simple_user.t option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
