module Ignore_matching = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  enabled : bool; [@default true]
  ignore_matching : Ignore_matching.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
