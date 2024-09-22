type t = { msg : string } [@@deriving yojson { strict = true; meta = true }, show, eq]
