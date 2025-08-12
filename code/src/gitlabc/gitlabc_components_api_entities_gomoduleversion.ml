type t = {
  time : string option; [@default None] [@key "Time"]
  version : string option; [@default None] [@key "Version"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
