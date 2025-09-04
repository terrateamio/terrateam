type t = {
  created_at : string option; [@default None]
  expires_at : string option; [@default None]
  id : int option; [@default None]
  key : string option; [@default None]
  title : string option; [@default None]
  usage_type : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
