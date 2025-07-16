type t = {
  branch : string option; [@default None]
  tag : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
