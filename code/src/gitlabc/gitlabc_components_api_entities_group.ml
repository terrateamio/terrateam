module Default_branch_protection = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Default_branch_protection_defaults = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Parent_id = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  archived : bool option; [@default None]
  avatar_url : string option; [@default None]
  created_at : string;
  default_branch : string option; [@default None]
  default_branch_protection : Default_branch_protection.t option; [@default None]
  default_branch_protection_defaults : Default_branch_protection_defaults.t option; [@default None]
  description : string option; [@default None]
  full_name : string;
  full_path : string option; [@default None]
  id : int;
  name : string;
  organization_id : int option; [@default None]
  parent_id : Parent_id.t option; [@default None]
  path : string option; [@default None]
  visibility : string option; [@default None]
  web_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
