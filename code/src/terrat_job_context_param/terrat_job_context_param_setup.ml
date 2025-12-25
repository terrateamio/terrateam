module Type = struct
  let t_of_yojson = function
    | `String "setup" -> Ok "setup"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { type_ : Type.t [@key "type"] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
