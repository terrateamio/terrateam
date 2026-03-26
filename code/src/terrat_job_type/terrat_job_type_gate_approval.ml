module Tokens = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type_ = struct
  let t_of_yojson = function
    | `String "gate-approval" -> Ok `Gate_approval
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Gate_approval -> `String "gate-approval"

  type t = ([ `Gate_approval ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  tokens : Tokens.t;
  type_ : Type_.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
