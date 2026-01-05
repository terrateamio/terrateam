module Ids = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type_ = struct
  let t_of_yojson = function
    | `String "unlock" -> Ok "unlock"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  ids : Ids.t;
  type_ : Type_.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
