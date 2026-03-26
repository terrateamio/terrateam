module Primary = struct
  module Merge_type = struct
    let t_of_yojson = function
      | `String "fast-forward" -> Ok `Fast_forward
      | `String "merge" -> Ok `Merge
      | `String "none" -> Ok `None
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Fast_forward -> `String "fast-forward"
      | `Merge -> `String "merge"
      | `None -> `String "none"

    type t =
      ([ `Fast_forward
       | `Merge
       | `None
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
