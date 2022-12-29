type t = { href : string } [@@deriving yojson { strict = false; meta = true }, make, show, eq]
