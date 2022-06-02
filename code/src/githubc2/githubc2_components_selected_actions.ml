module Primary = struct
  module Patterns_allowed = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    github_owned_allowed : bool option; [@default None]
    patterns_allowed : Patterns_allowed.t option; [@default None]
    verified_allowed : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
