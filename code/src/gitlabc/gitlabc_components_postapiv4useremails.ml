type t = { email : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
