module Primary = struct
  module Status_ = struct
    let t_of_yojson = function
      | `String "added" -> Ok `Added
      | `String "changed" -> Ok `Changed
      | `String "copied" -> Ok `Copied
      | `String "modified" -> Ok `Modified
      | `String "removed" -> Ok `Removed
      | `String "renamed" -> Ok `Renamed
      | `String "unchanged" -> Ok `Unchanged
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Added -> `String "added"
      | `Changed -> `String "changed"
      | `Copied -> `String "copied"
      | `Modified -> `String "modified"
      | `Removed -> `String "removed"
      | `Renamed -> `String "renamed"
      | `Unchanged -> `String "unchanged"

    type t =
      ([ `Added
       | `Changed
       | `Copied
       | `Modified
       | `Removed
       | `Renamed
       | `Unchanged
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    additions : int;
    blob_url : string option; [@default None]
    changes : int;
    contents_url : string;
    deletions : int;
    filename : string;
    patch : string option; [@default None]
    previous_filename : string option; [@default None]
    raw_url : string option; [@default None]
    sha : string option; [@default None]
    status : Status_.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
