module Email = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module User_id = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  access_level : int;
  email : Email.t option; [@default None]
  expires_at : string option; [@default None]
  invite_source : string; [@default "invitations-api"]
  member_role_id : int option; [@default None]
  user_id : User_id.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
