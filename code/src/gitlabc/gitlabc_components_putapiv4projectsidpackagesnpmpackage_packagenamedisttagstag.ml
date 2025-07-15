type t = { package_name : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
