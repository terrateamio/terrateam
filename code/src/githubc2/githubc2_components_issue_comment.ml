module Primary = struct
  type t = {
    author_association : Githubc2_components_author_association.t;
    body : string option; [@default None]
    body_html : string option; [@default None]
    body_text : string option; [@default None]
    created_at : string;
    html_url : string;
    id : int;
    issue_url : string;
    node_id : string;
    performed_via_github_app : Githubc2_components_nullable_integration.t option; [@default None]
    reactions : Githubc2_components_reaction_rollup.t option; [@default None]
    updated_at : string;
    url : string;
    user : Githubc2_components_nullable_simple_user.t option;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
