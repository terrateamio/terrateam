type t = { token : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
