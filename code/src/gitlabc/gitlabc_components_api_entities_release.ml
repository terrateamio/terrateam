module Primary = struct
  module Links_ = struct
    module Primary = struct
      type t = {
        closed_issues_url : string option; [@default None]
        closed_merge_requests_url : string option; [@default None]
        edit_url : string option; [@default None]
        merged_merge_requests_url : string option; [@default None]
        opened_issues_url : string option; [@default None]
        opened_merge_requests_url : string option; [@default None]
        self : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Assets = struct
    module Primary = struct
      type t = {
        count : int option; [@default None]
        links : Gitlabc_components_api_entities_releases_link.t option; [@default None]
        sources : Gitlabc_components_api_entities_releases_source.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    links_ : Links_.t option; [@default None] [@key "_links"]
    assets : Assets.t option; [@default None]
    author : Gitlabc_components_api_entities_userbasic.t option; [@default None]
    commit : Gitlabc_components_api_entities_commit.t option; [@default None]
    commit_path : string option; [@default None]
    created_at : string option; [@default None]
    description : string option; [@default None]
    description_html : string option; [@default None]
    evidences : Gitlabc_components_api_entities_releases_evidence.t option; [@default None]
    milestones : Gitlabc_components_api_entities_milestonewithstats.t option; [@default None]
    name : string option; [@default None]
    released_at : string option; [@default None]
    tag_name : string option; [@default None]
    tag_path : string option; [@default None]
    upcoming_release : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
