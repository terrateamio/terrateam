module Primary = struct
  type t = {
    avatar_url : string option; [@default None]
    context : string;
    created_at : string;
    creator : Githubc2_components_nullable_simple_user.t option; [@default None]
    description : string option; [@default None]
    id : int;
    node_id : string;
    state : string;
    target_url : string option; [@default None]
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
