type t = { refresh_token : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
