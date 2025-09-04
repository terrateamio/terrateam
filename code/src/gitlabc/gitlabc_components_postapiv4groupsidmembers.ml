type t = {
  access_level : int;
  expires_at : string option; [@default None]
  invite_source : string; [@default "members-api"]
  user_id : int option; [@default None]
  username : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
