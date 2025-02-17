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

module Window = struct
  type t = {
    end_ : string; [@key "end"]
    start : string;
  }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

type t = {
  reconcile : bool; [@default false]
  schedule : Schedule.t;
  tag_query : string;
  window : Window.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
