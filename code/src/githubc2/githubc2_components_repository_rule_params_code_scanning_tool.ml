module Primary = struct
  module Alerts_threshold = struct
    let t_of_yojson = function
      | `String "none" -> Ok "none"
      | `String "errors" -> Ok "errors"
      | `String "errors_and_warnings" -> Ok "errors_and_warnings"
      | `String "all" -> Ok "all"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Security_alerts_threshold = struct
    let t_of_yojson = function
      | `String "none" -> Ok "none"
      | `String "critical" -> Ok "critical"
      | `String "high_or_higher" -> Ok "high_or_higher"
      | `String "medium_or_higher" -> Ok "medium_or_higher"
      | `String "all" -> Ok "all"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    alerts_threshold : Alerts_threshold.t;
    security_alerts_threshold : Security_alerts_threshold.t;
    tool : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
