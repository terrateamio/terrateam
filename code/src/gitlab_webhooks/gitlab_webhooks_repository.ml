type t = { name : string } [@@deriving yojson { strict = false; meta = true }, make, show, eq]
