module Primary = struct
  type t = {
    avatar_url : string option;
    context : string;
    created_at : string;
    creator : Githubc2_components_nullable_simple_user.t option;
    description : string option;
    id : int;
    node_id : string;
    state : string;
    target_url : string option;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
