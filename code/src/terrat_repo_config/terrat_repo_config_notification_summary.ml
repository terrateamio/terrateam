type t = { enabled : bool [@default true] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
