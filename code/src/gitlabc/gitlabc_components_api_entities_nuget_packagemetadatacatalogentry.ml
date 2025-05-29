module Primary = struct
  module DependencyGroups = struct
    type t = Gitlabc_components_api_entities_nuget_dependencygroup.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    id_ : string option; [@default None] [@key "@id"]
    authors : string option; [@default None]
    dependencygroups : DependencyGroups.t option; [@default None] [@key "dependencyGroups"]
    description : string option; [@default None]
    iconurl : string option; [@default None] [@key "iconUrl"]
    id : string option; [@default None]
    licenseurl : string option; [@default None] [@key "licenseUrl"]
    packagecontent : string option; [@default None] [@key "packageContent"]
    projecturl : string option; [@default None] [@key "projectUrl"]
    published : string option; [@default None]
    summary : string option; [@default None]
    tags : string option; [@default None]
    version : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
