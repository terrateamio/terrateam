type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
