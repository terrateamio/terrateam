module Primary = struct
  module Permissions = struct
    let t_of_yojson = function
      | `String "read" -> Ok "read"
      | `String "write" -> Ok "write"
      | `String "admin" -> Ok "admin"
      | `String "triage" -> Ok "triage"
      | `String "maintain" -> Ok "maintain"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string;
    expired : bool option; [@default None]
    html_url : string;
    id : int;
    invitee : Githubc2_components_nullable_simple_user.t option;
    inviter : Githubc2_components_nullable_simple_user.t option;
    node_id : string;
    permissions : Permissions.t;
    repository : Githubc2_components_minimal_repository.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
