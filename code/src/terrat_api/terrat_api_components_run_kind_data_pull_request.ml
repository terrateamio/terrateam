type t = { id : string } [@@deriving yojson { strict = true; meta = true }, show, eq]
