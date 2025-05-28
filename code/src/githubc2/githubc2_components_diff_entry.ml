module Primary = struct
  module Status_ = struct
    let t_of_yojson = function
      | `String "added" -> Ok "added"
      | `String "removed" -> Ok "removed"
      | `String "modified" -> Ok "modified"
      | `String "renamed" -> Ok "renamed"
      | `String "copied" -> Ok "copied"
      | `String "changed" -> Ok "changed"
      | `String "unchanged" -> Ok "unchanged"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    additions : int;
    blob_url : string;
    changes : int;
    contents_url : string;
    deletions : int;
    filename : string;
    patch : string option; [@default None]
    previous_filename : string option; [@default None]
    raw_url : string;
    sha : string;
    status : Status_.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
