module State = struct
  let t_of_yojson = function
    | `String "awaiting" -> Ok "awaiting"
    | `String "active" -> Ok "active"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { state : State.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
