type t = {
  expires_at : string option; [@default None]
  group_access : int;
  group_id : int;
  member_role_id : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
