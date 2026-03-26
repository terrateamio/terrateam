module Primary = struct
  module Access_level = struct
    let t_of_yojson = function
      | `String "none" -> Ok `None
      | `String "organization" -> Ok `Organization
      | `String "user" -> Ok `User
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `None -> `String "none"
      | `Organization -> `String "organization"
      | `User -> `String "user"

    type t =
      ([ `None
       | `Organization
       | `User
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { access_level : Access_level.t }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
