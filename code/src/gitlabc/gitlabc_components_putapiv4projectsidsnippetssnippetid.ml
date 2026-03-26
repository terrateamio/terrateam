module Files = struct
  module Items = struct
    module Primary = struct
      module Action = struct
        let t_of_yojson = function
          | `String "create" -> Ok `Create
          | `String "delete" -> Ok `Delete
          | `String "move" -> Ok `Move
          | `String "update" -> Ok `Update
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Create -> `String "create"
          | `Delete -> `String "delete"
          | `Move -> `String "move"
          | `Update -> `String "update"

        type t =
          ([ `Create
           | `Delete
           | `Move
           | `Update
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        action : Action.t;
        content : string option; [@default None]
        file_path : string option; [@default None]
        previous_path : string option; [@default None]
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
  file_name : string option; [@default None]
  files : Files.t option; [@default None]
  title : string option; [@default None]
  visibility : Visibility.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
