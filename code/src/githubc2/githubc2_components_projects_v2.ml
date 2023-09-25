module Primary = struct
  type t = {
    closed_at : string option;
    created_at : string;
    creator : Githubc2_components_simple_user.t;
    deleted_at : string option;
    deleted_by : Githubc2_components_nullable_simple_user.t option;
    description : string option;
    id : float;
    node_id : string;
    number : int;
    owner : Githubc2_components_simple_user.t;
    public : bool;
    short_description : string option;
    title : string;
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
