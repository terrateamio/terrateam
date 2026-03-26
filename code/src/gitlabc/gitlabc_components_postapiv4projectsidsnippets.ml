module Files = struct
  module Items = struct
    module Primary = struct
      type t = {
        content : string;
        file_path : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Visibility = struct
  let t_of_yojson = function
    | `String "internal" -> Ok `Internal
    | `String "private" -> Ok `Private
    | `String "public" -> Ok `Public
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Internal -> `String "internal"
    | `Private -> `String "private"
    | `Public -> `String "public"

  type t =
    ([ `Internal
     | `Private
     | `Public
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  content : string option; [@default None]
  description : string option; [@default None]
  file_name : string;
  files : Files.t option; [@default None]
  title : string;
  visibility : Visibility.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
