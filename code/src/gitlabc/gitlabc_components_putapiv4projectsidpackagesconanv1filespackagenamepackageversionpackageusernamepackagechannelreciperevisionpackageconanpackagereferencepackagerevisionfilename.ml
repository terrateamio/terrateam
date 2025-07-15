type t = { file : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
