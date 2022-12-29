module Primary = struct
  module Merge_type = struct
    let t_of_yojson = function
      | `String "merge" -> Ok "merge"
      | `String "fast-forward" -> Ok "fast-forward"
      | `String "none" -> Ok "none"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    base_branch : string option; [@default None]
    merge_type : Merge_type.t option; [@default None]
    message : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
