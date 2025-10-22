type t = { result : bool } [@@deriving yojson { strict = false; meta = true }, show, eq]
