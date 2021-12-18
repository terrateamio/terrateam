module Cmd = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show]
end

module Type = struct
  let t_of_yojson = function
    | `String "env" -> Ok "env"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  cmd : Cmd.t;
  name : string;
  trim_trailing_newlines : bool; [@default true]
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show]
