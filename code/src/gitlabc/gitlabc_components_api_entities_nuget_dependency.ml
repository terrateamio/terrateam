type t = {
  id_ : string option; [@default None] [@key "@id"]
  type_ : string option; [@default None] [@key "@type"]
  id : string option; [@default None]
  range : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
