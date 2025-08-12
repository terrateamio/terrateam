type t = {
  approval_password : string option; [@default None]
  sha : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
