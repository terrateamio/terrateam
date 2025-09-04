type t = {
  access_level : int option; [@default None]
  member_role_id : int option; [@default None]
  name : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
