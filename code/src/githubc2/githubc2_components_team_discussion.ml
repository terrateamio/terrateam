module Primary = struct
  type t = {
    author : Githubc2_components_nullable_simple_user.t option; [@default None]
    body : string;
    body_html : string;
    body_version : string;
    comments_count : int;
    comments_url : string;
    created_at : string;
    html_url : string;
    last_edited_at : string option; [@default None]
    node_id : string;
    number : int;
    pinned : bool;
    private_ : bool; [@key "private"]
    reactions : Githubc2_components_reaction_rollup.t option; [@default None]
    team_url : string;
    title : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
