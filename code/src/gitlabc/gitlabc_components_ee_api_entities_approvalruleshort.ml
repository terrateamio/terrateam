type t = {
  id : int option; [@default None]
  name : string option; [@default None]
  rule_type : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
