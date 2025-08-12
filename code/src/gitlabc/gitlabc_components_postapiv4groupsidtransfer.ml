type t = { group_id : int option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
