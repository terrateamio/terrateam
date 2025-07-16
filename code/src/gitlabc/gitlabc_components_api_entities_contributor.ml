type t = {
  additions : int option; [@default None]
  commits : int option; [@default None]
  deletions : int option; [@default None]
  email : string option; [@default None]
  name : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
