type t = { chart : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
