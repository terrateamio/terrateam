module Primary = struct
  module Content = struct
    let t_of_yojson = function
      | `String "+1" -> Ok "+1"
      | `String "-1" -> Ok "-1"
      | `String "laugh" -> Ok "laugh"
      | `String "confused" -> Ok "confused"
      | `String "heart" -> Ok "heart"
      | `String "hooray" -> Ok "hooray"
      | `String "rocket" -> Ok "rocket"
      | `String "eyes" -> Ok "eyes"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    content : Content.t;
    created_at : string;
    id : int;
    node_id : string;
    user : Githubc2_components_nullable_simple_user.t option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
