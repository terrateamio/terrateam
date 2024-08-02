module Author = struct
  module All_of = struct
    module Primary = struct
      type t = {
        avatar_url : string;
        email : string option; [@default None]
        events_url : string;
        followers_url : string;
        following_url : string;
        gists_url : string;
        gravatar_id : string option;
        html_url : string;
        id : int;
        login : string;
        name : string option; [@default None]
        node_id : string;
        organizations_url : string;
        received_events_url : string;
        repos_url : string;
        site_admin : bool;
        starred_at : string option; [@default None]
        starred_url : string;
        subscriptions_url : string;
        type_ : string; [@key "type"]
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      type t = {
        avatar_url : string;
        email : string option; [@default None]
        events_url : string;
        followers_url : string;
        following_url : string;
        gists_url : string;
        gravatar_id : string option;
        html_url : string;
        id : int;
        login : string;
        name : string option; [@default None]
        node_id : string;
        organizations_url : string;
        received_events_url : string;
        repos_url : string;
        site_admin : bool;
        starred_at : string option; [@default None]
        starred_url : string;
        subscriptions_url : string;
        type_ : string; [@key "type"]
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module Collaborating_teams = struct
  type t = Githubc2_components_team.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Collaborating_users = struct
  type t = Githubc2_components_simple_user.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Credits = struct
  module Items = struct
    module Primary = struct
      type t = {
        login : string option; [@default None]
        type_ : Githubc2_components_security_advisory_credit_types.t option;
            [@default None] [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Credits_detailed = struct
  type t = Githubc2_components_repository_advisory_credit.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Cvss = struct
  module Primary = struct
    type t = {
      score : float option;
      vector_string : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Cwe_ids = struct
  type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Cwes = struct
  module Items = struct
    module Primary = struct
      type t = {
        cwe_id : string;
        name : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Identifiers = struct
  module Items = struct
    module Primary = struct
      module Type = struct
        let t_of_yojson = function
          | `String "CVE" -> Ok "CVE"
          | `String "GHSA" -> Ok "GHSA"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        type_ : Type.t; [@key "type"]
        value : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Private_fork = struct
  module All_of = struct
    module Primary = struct
      type t = {
        archive_url : string;
        assignees_url : string;
        blobs_url : string;
        branches_url : string;
        collaborators_url : string;
        comments_url : string;
        commits_url : string;
        compare_url : string;
        contents_url : string;
        contributors_url : string;
        deployments_url : string;
        description : string option;
        downloads_url : string;
        events_url : string;
        fork : bool;
        forks_url : string;
        full_name : string;
        git_commits_url : string;
        git_refs_url : string;
        git_tags_url : string;
        hooks_url : string;
        html_url : string;
        id : int;
        issue_comment_url : string;
        issue_events_url : string;
        issues_url : string;
        keys_url : string;
        labels_url : string;
        languages_url : string;
        merges_url : string;
        milestones_url : string;
        name : string;
        node_id : string;
        notifications_url : string;
        owner : Githubc2_components_simple_user.t;
        private_ : bool; [@key "private"]
        pulls_url : string;
        releases_url : string;
        stargazers_url : string;
        statuses_url : string;
        subscribers_url : string;
        subscription_url : string;
        tags_url : string;
        teams_url : string;
        trees_url : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      type t = {
        archive_url : string;
        assignees_url : string;
        blobs_url : string;
        branches_url : string;
        collaborators_url : string;
        comments_url : string;
        commits_url : string;
        compare_url : string;
        contents_url : string;
        contributors_url : string;
        deployments_url : string;
        description : string option;
        downloads_url : string;
        events_url : string;
        fork : bool;
        forks_url : string;
        full_name : string;
        git_commits_url : string;
        git_refs_url : string;
        git_tags_url : string;
        hooks_url : string;
        html_url : string;
        id : int;
        issue_comment_url : string;
        issue_events_url : string;
        issues_url : string;
        keys_url : string;
        labels_url : string;
        languages_url : string;
        merges_url : string;
        milestones_url : string;
        name : string;
        node_id : string;
        notifications_url : string;
        owner : Githubc2_components_simple_user.t;
        private_ : bool; [@key "private"]
        pulls_url : string;
        releases_url : string;
        stargazers_url : string;
        statuses_url : string;
        subscribers_url : string;
        subscription_url : string;
        tags_url : string;
        teams_url : string;
        trees_url : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module Publisher = struct
  module All_of = struct
    module Primary = struct
      type t = {
        avatar_url : string;
        email : string option; [@default None]
        events_url : string;
        followers_url : string;
        following_url : string;
        gists_url : string;
        gravatar_id : string option;
        html_url : string;
        id : int;
        login : string;
        name : string option; [@default None]
        node_id : string;
        organizations_url : string;
        received_events_url : string;
        repos_url : string;
        site_admin : bool;
        starred_at : string option; [@default None]
        starred_url : string;
        subscriptions_url : string;
        type_ : string; [@key "type"]
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      type t = {
        avatar_url : string;
        email : string option; [@default None]
        events_url : string;
        followers_url : string;
        following_url : string;
        gists_url : string;
        gravatar_id : string option;
        html_url : string;
        id : int;
        login : string;
        name : string option; [@default None]
        node_id : string;
        organizations_url : string;
        received_events_url : string;
        repos_url : string;
        site_admin : bool;
        starred_at : string option; [@default None]
        starred_url : string;
        subscriptions_url : string;
        type_ : string; [@key "type"]
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module Severity = struct
  let t_of_yojson = function
    | `String "critical" -> Ok "critical"
    | `String "high" -> Ok "high"
    | `String "medium" -> Ok "medium"
    | `String "low" -> Ok "low"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module State = struct
  let t_of_yojson = function
    | `String "published" -> Ok "published"
    | `String "closed" -> Ok "closed"
    | `String "withdrawn" -> Ok "withdrawn"
    | `String "draft" -> Ok "draft"
    | `String "triage" -> Ok "triage"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Submission = struct
  module Primary = struct
    type t = { accepted : bool } [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Vulnerabilities = struct
  type t = Githubc2_components_repository_advisory_vulnerability.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  author : Author.t option;
  closed_at : string option;
  collaborating_teams : Collaborating_teams.t option;
  collaborating_users : Collaborating_users.t option;
  created_at : string option;
  credits : Credits.t option;
  credits_detailed : Credits_detailed.t option;
  cve_id : string option;
  cvss : Cvss.t option;
  cwe_ids : Cwe_ids.t option;
  cwes : Cwes.t option;
  description : string option;
  ghsa_id : string;
  html_url : string;
  identifiers : Identifiers.t;
  private_fork : Private_fork.t option;
  published_at : string option;
  publisher : Publisher.t option;
  severity : Severity.t option;
  state : State.t;
  submission : Submission.t option;
  summary : string;
  updated_at : string option;
  url : string;
  vulnerabilities : Vulnerabilities.t option;
  withdrawn_at : string option;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
