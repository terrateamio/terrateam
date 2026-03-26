module Actions = struct
  module Items = struct
    module Primary = struct
      module Action = struct
        let t_of_yojson = function
          | `String "chmod" -> Ok `Chmod
          | `String "create" -> Ok `Create
          | `String "delete" -> Ok `Delete
          | `String "move" -> Ok `Move
          | `String "update" -> Ok `Update
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Chmod -> `String "chmod"
          | `Create -> `String "create"
          | `Delete -> `String "delete"
          | `Move -> `String "move"
          | `Update -> `String "update"

        type t =
          ([ `Chmod
           | `Create
           | `Delete
           | `Move
           | `Update
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Encoding = struct
        let t_of_yojson = function
          | `String "base64" -> Ok `Base64
          | `String "text" -> Ok `Text
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Base64 -> `String "base64"
          | `Text -> `String "text"

        type t =
          ([ `Base64
           | `Text
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        action : Action.t;
        content : string;
        encoding : Encoding.t; [@default `Text]
        execute_filemode : bool;
        file_path : string;
        last_commit_id : string option; [@default None]
        previous_path : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  actions : Actions.t;
  author_email : string option; [@default None]
  author_name : string option; [@default None]
  branch : string;
  commit_message : string;
  force : bool; [@default false]
  start_branch : string option; [@default None]
  start_project : int option; [@default None]
  start_sha : string option; [@default None]
  stats : bool; [@default true]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
