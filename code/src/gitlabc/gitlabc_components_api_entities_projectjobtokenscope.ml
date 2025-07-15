type t = {
  inbound_enabled : bool option; [@default None]
  outbound_enabled : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
