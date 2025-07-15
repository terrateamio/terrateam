type t = { namespace : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
