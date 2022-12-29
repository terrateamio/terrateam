module Primary = struct
  module Commits = struct
    type t = Githubc2_components_commit.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Files = struct
    type t = Githubc2_components_diff_entry.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Status_ = struct
    let t_of_yojson = function
      | `String "diverged" -> Ok "diverged"
      | `String "ahead" -> Ok "ahead"
      | `String "behind" -> Ok "behind"
      | `String "identical" -> Ok "identical"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    ahead_by : int;
    base_commit : Githubc2_components_commit.t;
    behind_by : int;
    commits : Commits.t;
    diff_url : string;
    files : Files.t option; [@default None]
    html_url : string;
    merge_base_commit : Githubc2_components_commit.t;
    patch_url : string;
    permalink_url : string;
    status : Status_.t;
    total_commits : int;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
