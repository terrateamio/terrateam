type t = { skip_ci : bool option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
