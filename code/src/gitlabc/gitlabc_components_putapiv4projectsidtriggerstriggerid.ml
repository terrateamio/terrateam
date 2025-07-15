type t = { description : string option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
