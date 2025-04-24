module Primary = struct
  module Status_ = struct
    let t_of_yojson = function
      | `String "deployment_in_progress" -> Ok "deployment_in_progress"
      | `String "syncing_files" -> Ok "syncing_files"
      | `String "finished_file_sync" -> Ok "finished_file_sync"
      | `String "updating_pages" -> Ok "updating_pages"
      | `String "purging_cdn" -> Ok "purging_cdn"
      | `String "deployment_cancelled" -> Ok "deployment_cancelled"
      | `String "deployment_failed" -> Ok "deployment_failed"
      | `String "deployment_content_failed" -> Ok "deployment_content_failed"
      | `String "deployment_attempt_error" -> Ok "deployment_attempt_error"
      | `String "deployment_lost" -> Ok "deployment_lost"
      | `String "succeed" -> Ok "succeed"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { status : Status_.t option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
