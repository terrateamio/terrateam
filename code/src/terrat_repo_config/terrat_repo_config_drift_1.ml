module Schedule = struct
  let t_of_yojson = function
    | `String "hourly" -> Ok "hourly"
    | `String "daily" -> Ok "daily"
    | `String "weekly" -> Ok "weekly"
    | `String "monthly" -> Ok "monthly"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  enabled : bool; [@default false]
  reconcile : bool; [@default false]
  schedule : Schedule.t;
  tag_query : string option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
