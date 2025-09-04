module Primary = struct
  module Merge_method = struct
    let t_of_yojson = function
      | `String "merge" -> Ok "merge"
      | `String "squash" -> Ok "squash"
      | `String "rebase" -> Ok "rebase"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    commit_message : string option; [@default None]
    commit_title : string option; [@default None]
    enabled_by : Githubc2_components_simple_user.t option; [@default None]
    merge_method : Merge_method.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
