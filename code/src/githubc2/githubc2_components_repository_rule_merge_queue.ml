module Primary = struct
  module Parameters = struct
    module Primary = struct
      module Grouping_strategy = struct
        let t_of_yojson = function
          | `String "ALLGREEN" -> Ok "ALLGREEN"
          | `String "HEADGREEN" -> Ok "HEADGREEN"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Merge_method = struct
        let t_of_yojson = function
          | `String "MERGE" -> Ok "MERGE"
          | `String "SQUASH" -> Ok "SQUASH"
          | `String "REBASE" -> Ok "REBASE"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        check_response_timeout_minutes : int;
        grouping_strategy : Grouping_strategy.t;
        max_entries_to_build : int;
        max_entries_to_merge : int;
        merge_method : Merge_method.t;
        min_entries_to_merge : int;
        min_entries_to_merge_wait_minutes : int;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Type = struct
    let t_of_yojson = function
      | `String "merge_queue" -> Ok "merge_queue"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    parameters : Parameters.t option; [@default None]
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
