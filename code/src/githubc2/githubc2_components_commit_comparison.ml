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
      | `String "ahead" -> Ok `Ahead
      | `String "behind" -> Ok `Behind
      | `String "diverged" -> Ok `Diverged
      | `String "identical" -> Ok `Identical
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Ahead -> `String "ahead"
      | `Behind -> `String "behind"
      | `Diverged -> `String "diverged"
      | `Identical -> `String "identical"

    type t =
      ([ `Ahead
       | `Behind
       | `Diverged
       | `Identical
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
