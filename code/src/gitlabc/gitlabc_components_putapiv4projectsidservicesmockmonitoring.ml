type t = { use_inherited_settings : bool option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
