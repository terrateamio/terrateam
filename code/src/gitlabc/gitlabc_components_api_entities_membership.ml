type t = {
  access_level : string option; [@default None]
  source_id : string option; [@default None]
  source_name : string option; [@default None]
  source_type : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
