module Primary = struct
  module Content = struct
    let t_of_yojson = function
      | `String "+1" -> Ok `_1
      | `String "-1" -> Ok `_1_2
      | `String "confused" -> Ok `Confused
      | `String "eyes" -> Ok `Eyes
      | `String "heart" -> Ok `Heart
      | `String "hooray" -> Ok `Hooray
      | `String "laugh" -> Ok `Laugh
      | `String "rocket" -> Ok `Rocket
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `_1 -> `String "+1"
      | `_1_2 -> `String "-1"
      | `Confused -> `String "confused"
      | `Eyes -> `String "eyes"
      | `Heart -> `String "heart"
      | `Hooray -> `String "hooray"
      | `Laugh -> `String "laugh"
      | `Rocket -> `String "rocket"

    type t =
      ([ `_1
       | `_1_2
       | `Confused
       | `Eyes
       | `Heart
       | `Hooray
       | `Laugh
       | `Rocket
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    content : Content.t;
    created_at : string;
    id : int;
    node_id : string;
    user : Githubc2_components_nullable_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
