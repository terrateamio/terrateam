module Commits = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { commits : Commits.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
