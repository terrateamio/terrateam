type t = {
  developers_can_merge : bool option; [@default None]
  developers_can_push : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
