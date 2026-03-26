module Upload = struct
  module Primary = struct
    module Http_method = struct
      let t_of_yojson = function
        | `String "POST" -> Ok `POST
        | `String "PUT" -> Ok `PUT
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `POST -> `String "POST"
        | `PUT -> `String "PUT"

      type t =
        ([ `POST
         | `PUT
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      http_method : Http_method.t; [@default `PUT]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = {
  description : string option; [@default None]
  upload : Upload.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
