type t = {
  cn : string option; [@default None]
  filter : string option; [@default None]
  group_access : int option; [@default None]
  member_role_id : int option; [@default None]
  provider : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
