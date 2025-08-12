type t = {
  access_level : int;
  expires_at : string option; [@default None]
  member_role_id : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
