type t = {
  environment_scope : string option; [@default None]
  id : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
