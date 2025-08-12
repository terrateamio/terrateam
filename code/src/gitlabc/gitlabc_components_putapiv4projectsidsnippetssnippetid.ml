module Files = struct
  module Items = struct
    module Primary = struct
      module Action = struct
        let t_of_yojson = function
          | `String "create" -> Ok "create"
          | `String "update" -> Ok "update"
          | `String "delete" -> Ok "delete"
          | `String "move" -> Ok "move"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
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
    | `String "private" -> Ok "private"
    | `String "internal" -> Ok "internal"
    | `String "public" -> Ok "public"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
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
