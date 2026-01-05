type t = { branch : string } [@@deriving yojson { strict = true; meta = true }, make, show, eq]
