module Primary = struct
  module Files = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    author : Gitlabc_components_api_entities_userbasic.t option; [@default None]
    created_at : string option; [@default None]
    description : string option; [@default None]
    file_name : string option; [@default None]
    files : Files.t option; [@default None]
    http_url_to_repo : string option; [@default None]
    id : int option; [@default None]
    imported : bool option; [@default None]
    imported_from : string option; [@default None]
    project_id : int option; [@default None]
    raw_url : string option; [@default None]
    repository_storage : string option; [@default None]
    ssh_url_to_repo : string option; [@default None]
    title : string option; [@default None]
    updated_at : string option; [@default None]
    visibility : string option; [@default None]
    web_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
