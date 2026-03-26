module Primary = struct
  module Visibility = struct
    let t_of_yojson = function
      | `String "all" -> Ok `All
      | `String "private" -> Ok `Private
      | `String "selected" -> Ok `Selected
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `All -> `String "all"
      | `Private -> `String "private"
      | `Selected -> `String "selected"

    type t =
      ([ `All
       | `Private
       | `Selected
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string;
    name : string;
    selected_repositories_url : string;
    updated_at : string;
    visibility : Visibility.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
