module Primary = struct
  module Organization_permission = struct
    let t_of_yojson = function
      | `String "admin" -> Ok `Admin
      | `String "none" -> Ok `None
      | `String "read" -> Ok `Read
      | `String "write" -> Ok `Write
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Admin -> `String "admin"
      | `None -> `String "none"
      | `Read -> `String "read"
      | `Write -> `String "write"

    type t =
      ([ `Admin
       | `None
       | `Read
       | `Write
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    body : string option; [@default None]
    columns_url : string;
    created_at : string;
    creator : Githubc2_components_nullable_simple_user.t option; [@default None]
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
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
