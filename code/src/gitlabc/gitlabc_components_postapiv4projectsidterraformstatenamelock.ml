type t = {
  created : string; [@key "Created"]
  id : string; [@key "ID"]
  info : string; [@key "Info"]
  operation : string; [@key "Operation"]
  path : string; [@key "Path"]
  version : string; [@key "Version"]
  who : string; [@key "Who"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
