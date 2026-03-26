module Primary = struct
  module Security_severity_level = struct
    let t_of_yojson = function
      | `String "critical" -> Ok `Critical
      | `String "high" -> Ok `High
      | `String "low" -> Ok `Low
      | `String "medium" -> Ok `Medium
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Critical -> `String "critical"
      | `High -> `String "high"
      | `Low -> `String "low"
      | `Medium -> `String "medium"

    type t =
      ([ `Critical
       | `High
       | `Low
       | `Medium
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Severity = struct
    let t_of_yojson = function
      | `String "error" -> Ok `Error
      | `String "none" -> Ok `None
      | `String "note" -> Ok `Note
      | `String "warning" -> Ok `Warning
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Error -> `String "error"
      | `None -> `String "none"
      | `Note -> `String "note"
      | `Warning -> `String "warning"

    type t =
      ([ `Error
       | `None
       | `Note
       | `Warning
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Tags = struct
    type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    description : string option; [@default None]
    full_description : string option; [@default None]
    help : string option; [@default None]
    help_uri : string option; [@default None]
    id : string option; [@default None]
    name : string option; [@default None]
    security_severity_level : Security_severity_level.t option; [@default None]
    severity : Severity.t option; [@default None]
    tags : Tags.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
