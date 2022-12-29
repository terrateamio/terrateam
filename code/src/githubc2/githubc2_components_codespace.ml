module Primary = struct
  module Git_status = struct
    module Primary = struct
      type t = {
        ahead : int option; [@default None]
        behind : int option; [@default None]
        has_uncommitted_changes : bool option; [@default None]
        has_unpushed_changes : bool option; [@default None]
        ref_ : string option; [@default None] [@key "ref"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Location = struct
    let t_of_yojson = function
      | `String "EastUs" -> Ok "EastUs"
      | `String "SouthEastAsia" -> Ok "SouthEastAsia"
      | `String "WestEurope" -> Ok "WestEurope"
      | `String "WestUs2" -> Ok "WestUs2"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Recent_folders = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Runtime_constraints = struct
    module Primary = struct
      module Allowed_port_privacy_settings = struct
        type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        allowed_port_privacy_settings : Allowed_port_privacy_settings.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module State = struct
    let t_of_yojson = function
      | `String "Unknown" -> Ok "Unknown"
      | `String "Created" -> Ok "Created"
      | `String "Queued" -> Ok "Queued"
      | `String "Provisioning" -> Ok "Provisioning"
      | `String "Available" -> Ok "Available"
      | `String "Awaiting" -> Ok "Awaiting"
      | `String "Unavailable" -> Ok "Unavailable"
      | `String "Deleted" -> Ok "Deleted"
      | `String "Moved" -> Ok "Moved"
      | `String "Shutdown" -> Ok "Shutdown"
      | `String "Archived" -> Ok "Archived"
      | `String "Starting" -> Ok "Starting"
      | `String "ShuttingDown" -> Ok "ShuttingDown"
      | `String "Failed" -> Ok "Failed"
      | `String "Exporting" -> Ok "Exporting"
      | `String "Updating" -> Ok "Updating"
      | `String "Rebuilding" -> Ok "Rebuilding"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    billable_owner : Githubc2_components_simple_user.t;
    created_at : string;
    devcontainer_path : string option; [@default None]
    display_name : string option; [@default None]
    environment_id : string option;
    git_status : Git_status.t;
    id : int;
    idle_timeout_minutes : int option;
    idle_timeout_notice : string option; [@default None]
    last_known_stop_notice : string option; [@default None]
    last_used_at : string;
    location : Location.t;
    machine : Githubc2_components_nullable_codespace_machine.t option;
    machines_url : string;
    name : string;
    owner : Githubc2_components_simple_user.t;
    pending_operation : bool option; [@default None]
    pending_operation_disabled_reason : string option; [@default None]
    prebuild : bool option;
    pulls_url : string option;
    recent_folders : Recent_folders.t;
    repository : Githubc2_components_minimal_repository.t;
    retention_expires_at : string option; [@default None]
    retention_period_minutes : int option; [@default None]
    runtime_constraints : Runtime_constraints.t option; [@default None]
    start_url : string;
    state : State.t;
    stop_url : string;
    updated_at : string;
    url : string;
    web_url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
