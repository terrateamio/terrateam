type t = {
  created_at : string option; [@default None]
  file_path : string option; [@default None]
  filename : string option; [@default None]
  id : int option; [@default None]
  url : string option; [@default None]
  url_text : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
