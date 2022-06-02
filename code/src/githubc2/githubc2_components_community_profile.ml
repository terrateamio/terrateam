module Primary = struct
  module Files = struct
    module Primary = struct
      type t = {
        code_of_conduct : Githubc2_components_nullable_code_of_conduct_simple.t option;
        code_of_conduct_file : Githubc2_components_nullable_community_health_file.t option;
        contributing : Githubc2_components_nullable_community_health_file.t option;
        issue_template : Githubc2_components_nullable_community_health_file.t option;
        license : Githubc2_components_nullable_license_simple.t option;
        pull_request_template : Githubc2_components_nullable_community_health_file.t option;
        readme : Githubc2_components_nullable_community_health_file.t option;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    content_reports_enabled : bool option; [@default None]
    description : string option;
    documentation : string option;
    files : Files.t;
    health_percentage : int;
    updated_at : string option;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
