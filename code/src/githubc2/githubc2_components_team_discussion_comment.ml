module Primary = struct
  type t = {
    author : Githubc2_components_nullable_simple_user.t option;
    body : string;
    body_html : string;
    body_version : string;
    created_at : string;
    discussion_url : string;
    html_url : string;
    last_edited_at : string option;
    node_id : string;
    number : int;
    reactions : Githubc2_components_reaction_rollup.t option; [@default None]
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
