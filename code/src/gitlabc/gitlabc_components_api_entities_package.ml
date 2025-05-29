module Primary = struct
  module Links_ = struct
    module Primary = struct
      type t = {
        delete_api_path : string option; [@default None]
        web_path : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    links_ : Links_.t option; [@default None] [@key "_links"]
    conan_package_name : string option; [@default None]
    created_at : string option; [@default None]
    id : int option; [@default None]
    last_downloaded_at : string option; [@default None]
    name : string option; [@default None]
    package_type : string option; [@default None]
    pipeline : Gitlabc_components_api_entities_package_pipeline.t option; [@default None]
    pipelines : Gitlabc_components_api_entities_package_pipeline.t option; [@default None]
    project_id : int option; [@default None]
    project_path : string option; [@default None]
    status : string option; [@default None]
    tags : string option; [@default None]
    version : string option; [@default None]
    versions : Gitlabc_components_api_entities_packageversion.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
