type t = {
  name : string option; [@default None]
  user_xids : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
