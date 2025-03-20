module Apply = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Diff = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Init = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Name = struct
  let t_of_yojson = function
    | `String "custom" -> Ok "custom"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Outputs = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Plan = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Unsafe_apply = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  apply : Apply.t option; [@default None]
  diff : Diff.t option; [@default None]
  init : Init.t option; [@default None]
  name : Name.t;
  outputs : Outputs.t option; [@default None]
  plan : Plan.t option; [@default None]
  unsafe_apply : Unsafe_apply.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
