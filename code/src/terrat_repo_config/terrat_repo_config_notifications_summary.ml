type t = { enabled : bool [@default false] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
