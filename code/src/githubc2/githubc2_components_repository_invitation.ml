module Primary = struct
  module Permissions = struct
    let t_of_yojson = function
      | `String "admin" -> Ok `Admin
      | `String "maintain" -> Ok `Maintain
      | `String "read" -> Ok `Read
      | `String "triage" -> Ok `Triage
      | `String "write" -> Ok `Write
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Admin -> `String "admin"
      | `Maintain -> `String "maintain"
      | `Read -> `String "read"
      | `Triage -> `String "triage"
      | `Write -> `String "write"

    type t =
      ([ `Admin
       | `Maintain
       | `Read
       | `Triage
       | `Write
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string;
    expired : bool option; [@default None]
    html_url : string;
    id : int64;
    invitee : Githubc2_components_nullable_simple_user.t option; [@default None]
    inviter : Githubc2_components_nullable_simple_user.t option; [@default None]
    node_id : string;
    permissions : Permissions.t;
    repository : Githubc2_components_minimal_repository.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
