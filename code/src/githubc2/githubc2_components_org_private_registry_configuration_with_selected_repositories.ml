module Primary = struct
  module Registry_type = struct
    let t_of_yojson = function
      | `String "maven_repository" -> Ok "maven_repository"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Selected_repository_ids = struct
    type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

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
    registry_type : Registry_type.t;
    selected_repository_ids : Selected_repository_ids.t option; [@default None]
    updated_at : string;
    username : string option; [@default None]
    visibility : Visibility.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
