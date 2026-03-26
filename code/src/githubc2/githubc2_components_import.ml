module Primary = struct
  module Project_choices = struct
    module Items = struct
      module Primary = struct
        type t = {
          human_name : string option; [@default None]
          tfvc_project : string option; [@default None]
          vcs : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Status_ = struct
    let t_of_yojson = function
      | `String "auth" -> Ok `Auth
      | `String "auth_failed" -> Ok `Auth_failed
      | `String "choose" -> Ok `Choose
      | `String "complete" -> Ok `Complete
      | `String "detecting" -> Ok `Detecting
      | `String "detection_found_multiple" -> Ok `Detection_found_multiple
      | `String "detection_found_nothing" -> Ok `Detection_found_nothing
      | `String "detection_needs_auth" -> Ok `Detection_needs_auth
      | `String "error" -> Ok `Error
      | `String "importing" -> Ok `Importing
      | `String "mapping" -> Ok `Mapping
      | `String "none" -> Ok `None
      | `String "pushing" -> Ok `Pushing
      | `String "setup" -> Ok `Setup
      | `String "unknown" -> Ok `Unknown
      | `String "waiting_to_push" -> Ok `Waiting_to_push
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Auth -> `String "auth"
      | `Auth_failed -> `String "auth_failed"
      | `Choose -> `String "choose"
      | `Complete -> `String "complete"
      | `Detecting -> `String "detecting"
      | `Detection_found_multiple -> `String "detection_found_multiple"
      | `Detection_found_nothing -> `String "detection_found_nothing"
      | `Detection_needs_auth -> `String "detection_needs_auth"
      | `Error -> `String "error"
      | `Importing -> `String "importing"
      | `Mapping -> `String "mapping"
      | `None -> `String "none"
      | `Pushing -> `String "pushing"
      | `Setup -> `String "setup"
      | `Unknown -> `String "unknown"
      | `Waiting_to_push -> `String "waiting_to_push"

    type t =
      ([ `Auth
       | `Auth_failed
       | `Choose
       | `Complete
       | `Detecting
       | `Detection_found_multiple
       | `Detection_found_nothing
       | `Detection_needs_auth
       | `Error
       | `Importing
       | `Mapping
       | `None
       | `Pushing
       | `Setup
       | `Unknown
       | `Waiting_to_push
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    authors_count : int option; [@default None]
    authors_url : string;
    commit_count : int option; [@default None]
    error_message : string option; [@default None]
    failed_step : string option; [@default None]
    has_large_files : bool option; [@default None]
    html_url : string;
    import_percent : int option; [@default None]
    large_files_count : int option; [@default None]
    large_files_size : int option; [@default None]
    message : string option; [@default None]
    project_choices : Project_choices.t option; [@default None]
    push_percent : int option; [@default None]
    repository_url : string;
    status : Status_.t;
    status_text : string option; [@default None]
    svc_root : string option; [@default None]
    svn_root : string option; [@default None]
    tfvc_project : string option; [@default None]
    url : string;
    use_lfs : bool option; [@default None]
    vcs : string option; [@default None]
    vcs_url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
