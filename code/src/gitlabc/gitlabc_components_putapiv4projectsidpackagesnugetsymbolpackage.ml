type t = { package : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
