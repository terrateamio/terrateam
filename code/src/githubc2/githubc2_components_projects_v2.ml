module Primary = struct
  type t = {
    closed_at : string option; [@default None]
    created_at : string;
    creator : Githubc2_components_simple_user.t;
    deleted_at : string option; [@default None]
    deleted_by : Githubc2_components_nullable_simple_user.t option; [@default None]
    description : string option; [@default None]
    id : float;
    node_id : string;
    number : int;
    owner : Githubc2_components_simple_user.t;
    public : bool;
    short_description : string option; [@default None]
    title : string;
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
