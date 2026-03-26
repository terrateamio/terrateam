module Primary = struct
  module Registry_type = struct
    let t_of_yojson = function
      | `String "maven_repository" -> Ok `Maven_repository
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Maven_repository -> `String "maven_repository"

    type t = ([ `Maven_repository ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

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
    registry_type : Registry_type.t;
    updated_at : string;
    username : string option; [@default None]
    visibility : Visibility.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
