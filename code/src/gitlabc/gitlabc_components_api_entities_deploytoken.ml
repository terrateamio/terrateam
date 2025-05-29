module Primary = struct
  module Scopes = struct
    module Items = struct
      type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    expired : bool option; [@default None]
    expires_at : string option; [@default None]
    id : int option; [@default None]
    name : string option; [@default None]
    revoked : bool option; [@default None]
    scopes : Scopes.t option; [@default None]
    username : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
