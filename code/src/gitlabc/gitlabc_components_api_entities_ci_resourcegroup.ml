type t = {
  created_at : string option; [@default None]
  id : int option; [@default None]
  key : string option; [@default None]
  process_mode : string option; [@default None]
  updated_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
