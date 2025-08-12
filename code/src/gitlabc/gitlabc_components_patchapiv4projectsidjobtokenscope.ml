type t = { enabled : bool } [@@deriving yojson { strict = false; meta = true }, show, eq]
