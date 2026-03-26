type t = { collect : bool option [@default None] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
