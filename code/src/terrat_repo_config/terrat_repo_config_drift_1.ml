module Schedule = struct
  let t_of_yojson = function
    | `String "daily" -> Ok `Daily
    | `String "hourly" -> Ok `Hourly
    | `String "monthly" -> Ok `Monthly
    | `String "weekly" -> Ok `Weekly
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Daily -> `String "daily"
    | `Hourly -> `String "hourly"
    | `Monthly -> `String "monthly"
    | `Weekly -> `String "weekly"

  type t =
    ([ `Daily
     | `Hourly
     | `Monthly
     | `Weekly
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  enabled : bool; [@default false]
  reconcile : bool; [@default false]
  schedule : Schedule.t;
  tag_query : string option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
