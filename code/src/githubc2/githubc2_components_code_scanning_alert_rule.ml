module Primary = struct
  module Security_severity_level = struct
    let t_of_yojson = function
      | `String "low" -> Ok "low"
      | `String "medium" -> Ok "medium"
      | `String "high" -> Ok "high"
      | `String "critical" -> Ok "critical"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Severity = struct
    let t_of_yojson = function
      | `String "none" -> Ok "none"
      | `String "note" -> Ok "note"
      | `String "warning" -> Ok "warning"
      | `String "error" -> Ok "error"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Tags = struct
    type t = string list option [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    description : string option; [@default None]
    full_description : string option; [@default None]
    help : string option; [@default None]
    id : string option; [@default None]
    name : string option; [@default None]
    security_severity_level : Security_severity_level.t option; [@default None]
    severity : Severity.t option; [@default None]
    tags : Tags.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
