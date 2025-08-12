module Upload = struct
  module Primary = struct
    module Http_method = struct
      let t_of_yojson = function
        | `String "PUT" -> Ok "PUT"
        | `String "POST" -> Ok "POST"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      http_method : Http_method.t; [@default "PUT"]
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
