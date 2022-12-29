module Primary = struct
  module Access_level = struct
    let t_of_yojson = function
      | `String "none" -> Ok "none"
      | `String "organization" -> Ok "organization"
      | `String "enterprise" -> Ok "enterprise"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { access_level : Access_level.t }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
