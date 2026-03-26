module Primary = struct
  module Type = struct
    let t_of_yojson = function
      | `String "branch" -> Ok `Branch
      | `String "tag" -> Ok `Tag
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Branch -> `String "branch"
      | `Tag -> `String "tag"

    type t =
      ([ `Branch
       | `Tag
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    name : string;
    type_ : Type.t option; [@default None] [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
