type t = {
  key : string option; [@default None]
  value : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
