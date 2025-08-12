type t = {
  created_at : string option; [@default None]
  digest : string option; [@default None]
  location : string option; [@default None]
  name : string option; [@default None]
  path : string option; [@default None]
  revision : string option; [@default None]
  short_revision : string option; [@default None]
  total_size : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
