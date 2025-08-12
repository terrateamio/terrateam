type t = { msg : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
