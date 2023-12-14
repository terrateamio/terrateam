module State = struct
  let t_of_yojson = function
    | `String "aborted" -> Ok "aborted"
    | `String "pending" -> Ok "pending"
    | `String "running" -> Ok "running"
    | `String "completed" -> Ok "completed"
    | `String "failed" -> Ok "failed"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  id : string;
  name : string;
  state : State.t;
  updated_at : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
