type t = {
  format : string option; [@default None]
  url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
