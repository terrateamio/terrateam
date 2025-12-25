type t = { pull_request : int } [@@deriving yojson { strict = true; meta = true }, make, show, eq]
