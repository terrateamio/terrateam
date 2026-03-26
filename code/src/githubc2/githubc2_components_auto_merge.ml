module Primary = struct
  module Merge_method = struct
    let t_of_yojson = function
      | `String "merge" -> Ok `Merge
      | `String "rebase" -> Ok `Rebase
      | `String "squash" -> Ok `Squash
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Merge -> `String "merge"
      | `Rebase -> `String "rebase"
      | `Squash -> `String "squash"

    type t =
      ([ `Merge
       | `Rebase
       | `Squash
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
