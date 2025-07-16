type t = {
  access_level : string option; [@default None]
  created_at : string option; [@default None]
  created_by_name : string option; [@default None]
  expires_at : string option; [@default None]
  invite_email : string option; [@default None]
  invite_token : string option; [@default None]
  user_name : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
