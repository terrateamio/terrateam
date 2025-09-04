type t = {
  id_ : string option; [@default None] [@key "@id"]
  downloads : int option; [@default None]
  version : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
