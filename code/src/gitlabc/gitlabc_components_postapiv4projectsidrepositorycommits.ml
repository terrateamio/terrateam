module Actions = struct
  module Items = struct
    module Primary = struct
      module Action = struct
        let t_of_yojson = function
          | `String "create" -> Ok "create"
          | `String "update" -> Ok "update"
          | `String "move" -> Ok "move"
          | `String "delete" -> Ok "delete"
          | `String "chmod" -> Ok "chmod"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Encoding = struct
        let t_of_yojson = function
          | `String "text" -> Ok "text"
          | `String "base64" -> Ok "base64"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        action : Action.t;
        content : string;
        encoding : Encoding.t; [@default "text"]
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
