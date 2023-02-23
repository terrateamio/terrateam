module Type = struct
  let t_of_yojson = function
    | `String "drift_create_issue" -> Ok "drift_create_issue"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { type_ : Type.t option [@key "type"] [@default None] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
