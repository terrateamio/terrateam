module Primary = struct
  module Scopes = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    authorized_credential_expires_at : string option; [@default None]
    authorized_credential_id : int option;
    authorized_credential_note : string option; [@default None]
    authorized_credential_title : string option; [@default None]
    credential_accessed_at : string option;
    credential_authorized_at : string;
    credential_id : int;
    credential_type : string;
    fingerprint : string option; [@default None]
    login : string;
    scopes : Scopes.t option; [@default None]
    token_last_eight : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
