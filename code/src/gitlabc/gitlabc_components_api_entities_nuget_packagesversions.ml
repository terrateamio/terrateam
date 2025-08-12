module Versions = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { versions : Versions.t option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
