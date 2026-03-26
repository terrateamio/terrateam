module Completed_at = struct
  type t = unit [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Conclusion = struct
  type t = unit [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Status = struct
  let t_of_yojson = function
    | `String "pending" -> Ok `Pending
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Pending -> `String "pending"

  type t = ([ `Pending ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  completed_at : Completed_at.t;
  conclusion : Conclusion.t;
  name : string;
  number : int;
  started_at : string option; [@default None]
  status : Status.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
