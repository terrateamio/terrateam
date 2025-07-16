type t = {
  filename : string option; [@default None]
  size : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
