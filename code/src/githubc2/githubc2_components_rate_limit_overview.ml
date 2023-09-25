module Primary = struct
  module Resources = struct
    module Primary = struct
      type t = {
        actions_runner_registration : Githubc2_components_rate_limit.t option; [@default None]
        code_scanning_upload : Githubc2_components_rate_limit.t option; [@default None]
        code_search : Githubc2_components_rate_limit.t option; [@default None]
        core : Githubc2_components_rate_limit.t;
        dependency_snapshots : Githubc2_components_rate_limit.t option; [@default None]
        graphql : Githubc2_components_rate_limit.t option; [@default None]
        integration_manifest : Githubc2_components_rate_limit.t option; [@default None]
        scim : Githubc2_components_rate_limit.t option; [@default None]
        search : Githubc2_components_rate_limit.t;
        source_import : Githubc2_components_rate_limit.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    rate : Githubc2_components_rate_limit.t;
    resources : Resources.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
