type t = {
  dir : string option; [@default None]
  workspace : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
