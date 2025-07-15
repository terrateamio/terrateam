type t = {
  expires_at : string option; [@default None]
  group_access : int option; [@default None]
  group_id : int option; [@default None]
  id : int option; [@default None]
  member_role_id : int option; [@default None]
  project_id : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
