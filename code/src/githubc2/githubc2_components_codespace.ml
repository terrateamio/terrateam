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
      | `String "EastUs" -> Ok `EastUs
      | `String "SouthEastAsia" -> Ok `SouthEastAsia
      | `String "WestEurope" -> Ok `WestEurope
      | `String "WestUs2" -> Ok `WestUs2
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `EastUs -> `String "EastUs"
      | `SouthEastAsia -> `String "SouthEastAsia"
      | `WestEurope -> `String "WestEurope"
      | `WestUs2 -> `String "WestUs2"

    type t =
      ([ `EastUs
       | `SouthEastAsia
       | `WestEurope
       | `WestUs2
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
      | `String "Archived" -> Ok `Archived
      | `String "Available" -> Ok `Available
      | `String "Awaiting" -> Ok `Awaiting
      | `String "Created" -> Ok `Created
      | `String "Deleted" -> Ok `Deleted
      | `String "Exporting" -> Ok `Exporting
      | `String "Failed" -> Ok `Failed
      | `String "Moved" -> Ok `Moved
      | `String "Provisioning" -> Ok `Provisioning
      | `String "Queued" -> Ok `Queued
      | `String "Rebuilding" -> Ok `Rebuilding
      | `String "Shutdown" -> Ok `Shutdown
      | `String "ShuttingDown" -> Ok `ShuttingDown
      | `String "Starting" -> Ok `Starting
      | `String "Unavailable" -> Ok `Unavailable
      | `String "Unknown" -> Ok `Unknown
      | `String "Updating" -> Ok `Updating
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Archived -> `String "Archived"
      | `Available -> `String "Available"
      | `Awaiting -> `String "Awaiting"
      | `Created -> `String "Created"
      | `Deleted -> `String "Deleted"
      | `Exporting -> `String "Exporting"
      | `Failed -> `String "Failed"
      | `Moved -> `String "Moved"
      | `Provisioning -> `String "Provisioning"
      | `Queued -> `String "Queued"
      | `Rebuilding -> `String "Rebuilding"
      | `Shutdown -> `String "Shutdown"
      | `ShuttingDown -> `String "ShuttingDown"
      | `Starting -> `String "Starting"
      | `Unavailable -> `String "Unavailable"
      | `Unknown -> `String "Unknown"
      | `Updating -> `String "Updating"

    type t =
      ([ `Archived
       | `Available
       | `Awaiting
       | `Created
       | `Deleted
       | `Exporting
       | `Failed
       | `Moved
       | `Provisioning
       | `Queued
       | `Rebuilding
       | `Shutdown
       | `ShuttingDown
       | `Starting
       | `Unavailable
       | `Unknown
       | `Updating
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    billable_owner : Githubc2_components_simple_user.t;
    created_at : string;
    devcontainer_path : string option; [@default None]
    display_name : string option; [@default None]
    environment_id : string option; [@default None]
    git_status : Git_status.t;
    id : int64;
    idle_timeout_minutes : int option; [@default None]
    idle_timeout_notice : string option; [@default None]
    last_known_stop_notice : string option; [@default None]
    last_used_at : string;
    location : Location.t;
    machine : Githubc2_components_nullable_codespace_machine.t option; [@default None]
    machines_url : string;
    name : string;
    owner : Githubc2_components_simple_user.t;
    pending_operation : bool option; [@default None]
    pending_operation_disabled_reason : string option; [@default None]
    prebuild : bool option; [@default None]
    publish_url : string option; [@default None]
    pulls_url : string option; [@default None]
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
