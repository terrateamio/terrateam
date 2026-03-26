module Primary = struct
  module Domains = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State = struct
    let t_of_yojson = function
      | `String "approved" -> Ok `Approved
      | `String "authorization_created" -> Ok `Authorization_created
      | `String "authorization_pending" -> Ok `Authorization_pending
      | `String "authorization_revoked" -> Ok `Authorization_revoked
      | `String "authorized" -> Ok `Authorized
      | `String "bad_authz" -> Ok `Bad_authz
      | `String "destroy_pending" -> Ok `Destroy_pending
      | `String "dns_changed" -> Ok `Dns_changed
      | `String "errored" -> Ok `Errored
      | `String "issued" -> Ok `Issued
      | `String "new" -> Ok `New
      | `String "uploaded" -> Ok `Uploaded
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Approved -> `String "approved"
      | `Authorization_created -> `String "authorization_created"
      | `Authorization_pending -> `String "authorization_pending"
      | `Authorization_revoked -> `String "authorization_revoked"
      | `Authorized -> `String "authorized"
      | `Bad_authz -> `String "bad_authz"
      | `Destroy_pending -> `String "destroy_pending"
      | `Dns_changed -> `String "dns_changed"
      | `Errored -> `String "errored"
      | `Issued -> `String "issued"
      | `New -> `String "new"
      | `Uploaded -> `String "uploaded"

    type t =
      ([ `Approved
       | `Authorization_created
       | `Authorization_pending
       | `Authorization_revoked
       | `Authorized
       | `Bad_authz
       | `Destroy_pending
       | `Dns_changed
       | `Errored
       | `Issued
       | `New
       | `Uploaded
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    description : string;
    domains : Domains.t;
    expires_at : string option; [@default None]
    state : State.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
