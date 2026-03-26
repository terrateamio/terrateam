module Primary = struct
  module Alerts_threshold = struct
    let t_of_yojson = function
      | `String "all" -> Ok `All
      | `String "errors" -> Ok `Errors
      | `String "errors_and_warnings" -> Ok `Errors_and_warnings
      | `String "none" -> Ok `None
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `All -> `String "all"
      | `Errors -> `String "errors"
      | `Errors_and_warnings -> `String "errors_and_warnings"
      | `None -> `String "none"

    type t =
      ([ `All
       | `Errors
       | `Errors_and_warnings
       | `None
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Security_alerts_threshold = struct
    let t_of_yojson = function
      | `String "all" -> Ok `All
      | `String "critical" -> Ok `Critical
      | `String "high_or_higher" -> Ok `High_or_higher
      | `String "medium_or_higher" -> Ok `Medium_or_higher
      | `String "none" -> Ok `None
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `All -> `String "all"
      | `Critical -> `String "critical"
      | `High_or_higher -> `String "high_or_higher"
      | `Medium_or_higher -> `String "medium_or_higher"
      | `None -> `String "none"

    type t =
      ([ `All
       | `Critical
       | `High_or_higher
       | `Medium_or_higher
       | `None
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
