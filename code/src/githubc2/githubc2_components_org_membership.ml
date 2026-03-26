module Primary = struct
  module Permissions = struct
    module Primary = struct
      type t = { can_create_repository : bool }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Role = struct
    let t_of_yojson = function
      | `String "admin" -> Ok `Admin
      | `String "billing_manager" -> Ok `Billing_manager
      | `String "member" -> Ok `Member
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Admin -> `String "admin"
      | `Billing_manager -> `String "billing_manager"
      | `Member -> `String "member"

    type t =
      ([ `Admin
       | `Billing_manager
       | `Member
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State = struct
    let t_of_yojson = function
      | `String "active" -> Ok `Active
      | `String "pending" -> Ok `Pending
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Active -> `String "active"
      | `Pending -> `String "pending"

    type t =
      ([ `Active
       | `Pending
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    organization : Githubc2_components_organization_simple.t;
    organization_url : string;
    permissions : Permissions.t option; [@default None]
    role : Role.t;
    state : State.t;
    url : string;
    user : Githubc2_components_nullable_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
