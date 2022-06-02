module Primary = struct
  type t = {
    author_association : Githubc2_components_author_association.t;
    body : string;
    created_at : string;
    id : int;
    node_id : string;
    updated_at : string;
    url : string;
    user : Githubc2_components_nullable_simple_user.t option;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
