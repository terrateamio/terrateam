module Primary = struct
  module App = struct
    module Primary = struct
      type t = {
        client_id : string;
        name : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Scopes = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    app : App.t;
    created_at : string;
    id : int;
    scopes : Scopes.t;
    updated_at : string;
    url : string;
    user : Githubc2_components_nullable_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
