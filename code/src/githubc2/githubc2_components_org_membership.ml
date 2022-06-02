module Primary = struct
  module Permissions = struct
    module Primary = struct
      type t = { can_create_repository : bool }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Role = struct
    let t_of_yojson = function
      | `String "admin" -> Ok "admin"
      | `String "member" -> Ok "member"
      | `String "billing_manager" -> Ok "billing_manager"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module State = struct
    let t_of_yojson = function
      | `String "active" -> Ok "active"
      | `String "pending" -> Ok "pending"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    organization : Githubc2_components_organization_simple.t;
    organization_url : string;
    permissions : Permissions.t option; [@default None]
    role : Role.t;
    state : State.t;
    url : string;
    user : Githubc2_components_nullable_simple_user.t option;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
