type t = { avatar : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
