module Primary = struct
  module Organization_permission = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | `String "admin" -> Ok "admin"
      | `String "none" -> Ok "none"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    body : string option;
    columns_url : string;
    created_at : string;
    creator : Githubc2_components_nullable_simple_user.t option;
    html_url : string;
    id : int;
    name : string;
    node_id : string;
    number : int;
    organization_permission : Organization_permission.t option; [@default None]
    owner_url : string;
    private_ : bool option; [@default None] [@key "private"]
    state : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
