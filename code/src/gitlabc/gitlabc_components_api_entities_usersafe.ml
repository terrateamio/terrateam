type t = {
  id : int option; [@default None]
  name : string option; [@default None]
  username : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
