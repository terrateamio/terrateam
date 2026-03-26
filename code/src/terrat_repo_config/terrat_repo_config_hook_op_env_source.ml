module Cmd = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Method = struct
  let t_of_yojson = function
    | `String "source" -> Ok `Source
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Source -> `String "source"

  type t = ([ `Source ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Type = struct
  let t_of_yojson = function
    | `String "env" -> Ok `Env
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Env -> `String "env"

  type t = ([ `Env ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  cmd : Cmd.t;
  method_ : Method.t; [@key "method"]
  sensitive : bool; [@default false]
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
