type t = { avatar_url : string option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
