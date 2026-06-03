type t = { type_ : string [@key "type"] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
