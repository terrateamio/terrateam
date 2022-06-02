module Primary = struct
  module Project_choices = struct
    module Items = struct
      module Primary = struct
        type t = {
          human_name : string option; [@default None]
          tfvc_project : string option; [@default None]
          vcs : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Status_ = struct
    let t_of_yojson = function
      | `String "auth" -> Ok "auth"
      | `String "error" -> Ok "error"
      | `String "none" -> Ok "none"
      | `String "detecting" -> Ok "detecting"
      | `String "choose" -> Ok "choose"
      | `String "auth_failed" -> Ok "auth_failed"
      | `String "importing" -> Ok "importing"
      | `String "mapping" -> Ok "mapping"
      | `String "waiting_to_push" -> Ok "waiting_to_push"
      | `String "pushing" -> Ok "pushing"
      | `String "complete" -> Ok "complete"
      | `String "setup" -> Ok "setup"
      | `String "unknown" -> Ok "unknown"
      | `String "detection_found_multiple" -> Ok "detection_found_multiple"
      | `String "detection_found_nothing" -> Ok "detection_found_nothing"
      | `String "detection_needs_auth" -> Ok "detection_needs_auth"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
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
    vcs : string option;
    vcs_url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
