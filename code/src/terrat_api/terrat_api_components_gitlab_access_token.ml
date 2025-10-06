type t = { access_token : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
