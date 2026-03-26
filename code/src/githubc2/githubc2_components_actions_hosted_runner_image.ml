module Primary = struct
  module Source = struct
    let t_of_yojson = function
      | `String "custom" -> Ok `Custom
      | `String "github" -> Ok `Github
      | `String "partner" -> Ok `Partner
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Custom -> `String "custom"
      | `Github -> `String "github"
      | `Partner -> `String "partner"

    type t =
      ([ `Custom
       | `Github
       | `Partner
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    display_name : string;
    id : string;
    platform : string;
    size_gb : int;
    source : Source.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
