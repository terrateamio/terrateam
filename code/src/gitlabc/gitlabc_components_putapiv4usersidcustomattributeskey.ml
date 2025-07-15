type t = { value : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
