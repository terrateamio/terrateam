type t = { before : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
