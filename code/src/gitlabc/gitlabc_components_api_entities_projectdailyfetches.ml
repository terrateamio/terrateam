type t = {
  count : int option; [@default None]
  date : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
