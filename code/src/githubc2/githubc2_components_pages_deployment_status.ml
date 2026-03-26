module Primary = struct
  module Status_ = struct
    let t_of_yojson = function
      | `String "deployment_attempt_error" -> Ok `Deployment_attempt_error
      | `String "deployment_cancelled" -> Ok `Deployment_cancelled
      | `String "deployment_content_failed" -> Ok `Deployment_content_failed
      | `String "deployment_failed" -> Ok `Deployment_failed
      | `String "deployment_in_progress" -> Ok `Deployment_in_progress
      | `String "deployment_lost" -> Ok `Deployment_lost
      | `String "finished_file_sync" -> Ok `Finished_file_sync
      | `String "purging_cdn" -> Ok `Purging_cdn
      | `String "succeed" -> Ok `Succeed
      | `String "syncing_files" -> Ok `Syncing_files
      | `String "updating_pages" -> Ok `Updating_pages
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Deployment_attempt_error -> `String "deployment_attempt_error"
      | `Deployment_cancelled -> `String "deployment_cancelled"
      | `Deployment_content_failed -> `String "deployment_content_failed"
      | `Deployment_failed -> `String "deployment_failed"
      | `Deployment_in_progress -> `String "deployment_in_progress"
      | `Deployment_lost -> `String "deployment_lost"
      | `Finished_file_sync -> `String "finished_file_sync"
      | `Purging_cdn -> `String "purging_cdn"
      | `Succeed -> `String "succeed"
      | `Syncing_files -> `String "syncing_files"
      | `Updating_pages -> `String "updating_pages"

    type t =
      ([ `Deployment_attempt_error
       | `Deployment_cancelled
       | `Deployment_content_failed
       | `Deployment_failed
       | `Deployment_in_progress
       | `Deployment_lost
       | `Finished_file_sync
       | `Purging_cdn
       | `Succeed
       | `Syncing_files
       | `Updating_pages
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { status : Status_.t option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
