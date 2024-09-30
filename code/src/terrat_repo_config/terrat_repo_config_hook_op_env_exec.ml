module Cmd = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Method = struct
  let t_of_yojson = function
    | `String "exec" -> Ok "exec"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type = struct
  let t_of_yojson = function
    | `String "env" -> Ok "env"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  cmd : Cmd.t;
  method_ : Method.t option; [@key "method"] [@default None]
  name : string;
  sensitive : bool; [@default false]
  trim_trailing_newlines : bool; [@default true]
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
