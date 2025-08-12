module Scopes = struct
  module Items = struct
    type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  active : bool option; [@default None]
  created_at : string option; [@default None]
  description : string option; [@default None]
  expires_at : string option; [@default None]
  id : int option; [@default None]
  last_used_at : string option; [@default None]
  name : string option; [@default None]
  revoked : bool option; [@default None]
  scopes : Scopes.t option; [@default None]
  token : string option; [@default None]
  user_id : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
