module Primary = struct
  module Parameters = struct
    module Primary = struct
      module Grouping_strategy = struct
        let t_of_yojson = function
          | `String "ALLGREEN" -> Ok `ALLGREEN
          | `String "HEADGREEN" -> Ok `HEADGREEN
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `ALLGREEN -> `String "ALLGREEN"
          | `HEADGREEN -> `String "HEADGREEN"

        type t =
          ([ `ALLGREEN
           | `HEADGREEN
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Merge_method = struct
        let t_of_yojson = function
          | `String "MERGE" -> Ok `MERGE
          | `String "REBASE" -> Ok `REBASE
          | `String "SQUASH" -> Ok `SQUASH
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `MERGE -> `String "MERGE"
          | `REBASE -> `String "REBASE"
          | `SQUASH -> `String "SQUASH"

        type t =
          ([ `MERGE
           | `REBASE
           | `SQUASH
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
      | `String "merge_queue" -> Ok `Merge_queue
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Merge_queue -> `String "merge_queue"

    type t = ([ `Merge_queue ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    parameters : Parameters.t option; [@default None]
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
