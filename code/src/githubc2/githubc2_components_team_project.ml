module Primary = struct
  module Permissions = struct
    module Primary = struct
      type t = {
        admin : bool;
        read : bool;
        write : bool;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    body : string option;
    columns_url : string;
    created_at : string;
    creator : Githubc2_components_simple_user.t;
    html_url : string;
    id : int;
    name : string;
    node_id : string;
    number : int;
    organization_permission : string option; [@default None]
    owner_url : string;
    permissions : Permissions.t;
    private_ : bool option; [@default None] [@key "private"]
    state : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
