module Status = struct
  let t_of_yojson = function
    | `String "running" -> Ok "running"
    | `String "success" -> Ok "success"
    | `String "failed" -> Ok "failed"
    | `String "canceled" -> Ok "canceled"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { status : Status.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
