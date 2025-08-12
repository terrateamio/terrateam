type t = { id : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
