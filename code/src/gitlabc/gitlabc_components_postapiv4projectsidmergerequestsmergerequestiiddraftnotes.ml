module Position = struct
  module Primary = struct
    module Line_range = struct
      module Primary = struct
        module End = struct
          module Primary = struct
            type t = {
              line_code : string option; [@default None]
              new_line : string option; [@default None]
              old_line : string option; [@default None]
              type_ : string option; [@default None] [@key "type"]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Start = struct
          module Primary = struct
            type t = {
              line_code : string option; [@default None]
              new_line : string option; [@default None]
              old_line : string option; [@default None]
              type_ : string option; [@default None] [@key "type"]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          end_ : End.t option; [@default None] [@key "end"]
          start : Start.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Position_type = struct
      let t_of_yojson = function
        | `String "file" -> Ok `File
        | `String "image" -> Ok `Image
        | `String "text" -> Ok `Text
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `File -> `String "file"
        | `Image -> `String "image"
        | `Text -> `String "text"

      type t =
        ([ `File
         | `Image
         | `Text
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      base_sha : string;
      head_sha : string;
      height : int option; [@default None]
      line_range : Line_range.t option; [@default None]
      new_line : int option; [@default None]
      new_path : string option; [@default None]
      old_line : int option; [@default None]
      old_path : string option; [@default None]
      position_type : Position_type.t;
      start_sha : string;
      width : int option; [@default None]
      x : int option; [@default None]
      y : int option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = {
  commit_id : string option; [@default None]
  in_reply_to_discussion_id : string option; [@default None]
  note : string;
  position : Position.t option; [@default None]
  resolve_discussion : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
