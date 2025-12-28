module Type_ = struct
  let t_of_yojson = function
    | `String "repo-config" -> Ok "repo-config"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { type_ : Type_.t [@key "type"] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
