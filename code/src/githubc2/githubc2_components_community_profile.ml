module Primary = struct
  module Files = struct
    module Primary = struct
      type t = {
        code_of_conduct : Githubc2_components_nullable_code_of_conduct_simple.t option;
            [@default None]
        code_of_conduct_file : Githubc2_components_nullable_community_health_file.t option;
            [@default None]
        contributing : Githubc2_components_nullable_community_health_file.t option; [@default None]
        issue_template : Githubc2_components_nullable_community_health_file.t option;
            [@default None]
        license : Githubc2_components_nullable_license_simple.t option; [@default None]
        pull_request_template : Githubc2_components_nullable_community_health_file.t option;
            [@default None]
        readme : Githubc2_components_nullable_community_health_file.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    content_reports_enabled : bool option; [@default None]
    description : string option; [@default None]
    documentation : string option; [@default None]
    files : Files.t;
    health_percentage : int;
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
