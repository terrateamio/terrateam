type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
