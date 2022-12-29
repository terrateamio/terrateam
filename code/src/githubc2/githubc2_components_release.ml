module Primary = struct
  module Assets = struct
    type t = Githubc2_components_release_asset.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    assets : Assets.t;
    assets_url : string;
    author : Githubc2_components_simple_user.t;
    body : string option; [@default None]
    body_html : string option; [@default None]
    body_text : string option; [@default None]
    created_at : string;
    discussion_url : string option; [@default None]
    draft : bool;
    html_url : string;
    id : int;
    mentions_count : int option; [@default None]
    name : string option;
    node_id : string;
    prerelease : bool;
    published_at : string option;
    reactions : Githubc2_components_reaction_rollup.t option; [@default None]
    tag_name : string;
    tarball_url : string option;
    target_commitish : string;
    upload_url : string;
    url : string;
    zipball_url : string option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
