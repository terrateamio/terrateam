module Primary = struct
  module Resource_type = struct
    let t_of_yojson = function
      | `String "project" -> Ok "project"
      | `String "group" -> Ok "group"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Scopes = struct
    module Items = struct
      type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    access_level : int option; [@default None]
    active : bool option; [@default None]
    created_at : string option; [@default None]
    description : string option; [@default None]
    expires_at : string option; [@default None]
    id : int option; [@default None]
    last_used_at : string option; [@default None]
    name : string option; [@default None]
    resource_id : int option; [@default None]
    resource_type : Resource_type.t option; [@default None]
    revoked : bool option; [@default None]
    scopes : Scopes.t option; [@default None]
    token : string option; [@default None]
    user_id : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
