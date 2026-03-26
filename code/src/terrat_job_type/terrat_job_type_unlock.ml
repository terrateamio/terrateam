module Ids = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type_ = struct
  let t_of_yojson = function
    | `String "unlock" -> Ok `Unlock
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Unlock -> `String "unlock"

  type t = ([ `Unlock ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  ids : Ids.t;
  type_ : Type_.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
