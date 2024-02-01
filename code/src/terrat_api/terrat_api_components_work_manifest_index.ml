module Dirs = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type = struct
  let t_of_yojson = function
    | `String "index" -> Ok "index"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  dirs : Dirs.t;
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
