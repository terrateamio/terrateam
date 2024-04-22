module Resourcely = struct
  type t = { enabled : bool } [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

type t = { resourcely : Resourcely.t option [@default None] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
