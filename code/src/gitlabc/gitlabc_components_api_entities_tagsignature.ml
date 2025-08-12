type t = {
  signature : string option; [@default None]
  signature_type : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
