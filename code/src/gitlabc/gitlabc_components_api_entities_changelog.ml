type t = { notes : string option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
