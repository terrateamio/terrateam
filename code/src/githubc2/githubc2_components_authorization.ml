module Primary = struct
  module App = struct
    module Primary = struct
      type t = {
        client_id : string;
        name : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Scopes = struct
    type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    app : App.t;
    created_at : string;
    expires_at : string option; [@default None]
    fingerprint : string option; [@default None]
    hashed_token : string option; [@default None]
    id : int64;
    installation : Githubc2_components_nullable_scoped_installation.t option; [@default None]
    note : string option; [@default None]
    note_url : string option; [@default None]
    scopes : Scopes.t option; [@default None]
    token : string;
    token_last_eight : string option; [@default None]
    updated_at : string;
    url : string;
    user : Githubc2_components_nullable_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
