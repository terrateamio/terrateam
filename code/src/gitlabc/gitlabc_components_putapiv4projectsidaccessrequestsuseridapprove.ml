type t = { access_level : int [@default 30] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
