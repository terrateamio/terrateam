type t = {
  expires_at : string option; [@default None]
  pin : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
