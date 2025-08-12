type t = { module_version : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
