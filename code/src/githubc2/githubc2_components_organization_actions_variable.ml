module Primary = struct
  module Visibility = struct
    let t_of_yojson = function
      | `String "all" -> Ok "all"
      | `String "private" -> Ok "private"
      | `String "selected" -> Ok "selected"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string;
    name : string;
    selected_repositories_url : string option; [@default None]
    updated_at : string;
    value : string;
    visibility : Visibility.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
