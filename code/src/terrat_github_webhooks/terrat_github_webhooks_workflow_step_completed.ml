module Status = struct
  let t_of_yojson = function
    | `String "completed" -> Ok "completed"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  completed_at : string;
  conclusion : string;
  name : string;
  number : int;
  started_at : string;
  status : Status.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
