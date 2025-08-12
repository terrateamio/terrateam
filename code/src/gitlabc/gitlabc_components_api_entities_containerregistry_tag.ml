type t = {
  location : string option; [@default None]
  name : string option; [@default None]
  path : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
