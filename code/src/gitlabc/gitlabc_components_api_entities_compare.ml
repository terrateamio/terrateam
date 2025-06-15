module Primary = struct
  module Commits = struct
    type t = Gitlabc_components_api_entities_commit.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Diffs = struct
    type t = Gitlabc_components_api_entities_diff.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    commit : Gitlabc_components_api_entities_commit.t option; [@default None]
    commits : Commits.t option; [@default None]
    compare_same_ref : bool option; [@default None]
    compare_timeout : bool option; [@default None]
    diffs : Diffs.t option; [@default None]
    web_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
