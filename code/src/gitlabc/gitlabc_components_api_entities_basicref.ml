type t = {
  name : string option; [@default None]
  type_ : string option; [@default None] [@key "type"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
