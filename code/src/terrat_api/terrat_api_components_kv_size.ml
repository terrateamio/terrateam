type t = { size : int } [@@deriving yojson { strict = false; meta = true }, show, eq]
