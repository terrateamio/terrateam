module Primary = struct
  module Ref_type = struct
    let t_of_yojson = function
      | `String "tag" -> Ok "tag"
      | `String "branch" -> Ok "branch"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    description : string option;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    master_branch : string;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    pusher_type : string;
    ref_ : string; [@key "ref"]
    ref_type : Ref_type.t;
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user_webhooks.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
