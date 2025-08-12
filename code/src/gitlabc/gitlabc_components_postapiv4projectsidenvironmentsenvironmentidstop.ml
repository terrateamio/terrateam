type t = { force : bool [@default false] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
