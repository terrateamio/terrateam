type t = {
  auto_ssl_enabled : bool option; [@default None]
  certificate : string option; [@default None]
  key : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
