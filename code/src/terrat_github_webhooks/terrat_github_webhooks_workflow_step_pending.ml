module Completed_at = struct
  type t = unit [@@deriving yojson { strict = false; meta = true }, show]
end

module Conclusion = struct
  type t = unit [@@deriving yojson { strict = false; meta = true }, show]
end

module Status = struct
  let t_of_yojson = function
    | `String "pending" -> Ok "pending"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  completed_at : Completed_at.t;
  conclusion : Conclusion.t;
  name : string;
  number : int;
  started_at : string;
  status : Status.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show]
