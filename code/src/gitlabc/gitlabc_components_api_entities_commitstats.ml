type t = {
  additions : int option; [@default None]
  deletions : int option; [@default None]
  total : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
