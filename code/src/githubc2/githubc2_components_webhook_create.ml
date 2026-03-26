module Primary = struct
  module Ref_type = struct
    let t_of_yojson = function
      | `String "branch" -> Ok `Branch
      | `String "tag" -> Ok `Tag
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Branch -> `String "branch"
      | `Tag -> `String "tag"

    type t =
      ([ `Branch
       | `Tag
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    description : string option; [@default None]
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    master_branch : string;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    pusher_type : string;
    ref_ : string; [@key "ref"]
    ref_type : Ref_type.t;
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
