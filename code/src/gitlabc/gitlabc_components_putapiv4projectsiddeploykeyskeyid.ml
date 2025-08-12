type t = {
  can_push : bool option; [@default None]
  title : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
