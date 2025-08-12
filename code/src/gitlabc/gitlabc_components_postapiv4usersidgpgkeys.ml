type t = { key : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
