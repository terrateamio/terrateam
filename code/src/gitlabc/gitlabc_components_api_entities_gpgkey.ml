type t = {
  created_at : string option; [@default None]
  id : string option; [@default None]
  key : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
