type t = { destination_storage_name : string option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
