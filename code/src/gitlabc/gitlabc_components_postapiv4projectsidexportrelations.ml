type t = { batched : bool option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
