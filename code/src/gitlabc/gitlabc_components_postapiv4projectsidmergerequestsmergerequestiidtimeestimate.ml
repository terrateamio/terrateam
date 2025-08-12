type t = { duration : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
