type t = { name : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
