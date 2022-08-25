module Env = struct
  module Additional = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

module Extra_args = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show]
end

module Retry = struct
  type t = {
    backoff : float; [@default 3.]
    enabled : bool; [@default false]
    initial_sleep : int; [@default 5]
    tries : int; [@default 3]
  }
  [@@deriving yojson { strict = true; meta = true }, make, show]
end

module Type = struct
  let t_of_yojson = function
    | `String "apply" -> Ok "apply"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  env : Env.t option; [@default None]
  extra_args : Extra_args.t option; [@default None]
  retry : Retry.t option; [@default None]
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show]
