module Links_ = struct
  type t = {
    comments : Terrat_github_webhooks_link.t;
    commits : Terrat_github_webhooks_link.t;
    html : Terrat_github_webhooks_link.t;
    issue : Terrat_github_webhooks_link.t;
    review_comment : Terrat_github_webhooks_link.t;
    review_comments : Terrat_github_webhooks_link.t;
    self : Terrat_github_webhooks_link.t;
    statuses : Terrat_github_webhooks_link.t;
  }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

module Assignees = struct
  type t = Terrat_github_webhooks_user.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Base = struct
  type t = {
    label : string;
    ref_ : string; [@key "ref"]
    repo : Terrat_github_webhooks_repository.t;
    sha : string;
    user : Terrat_github_webhooks_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

module Head = struct
  type t = {
    label : string;
    ref_ : string; [@key "ref"]
    repo : Terrat_github_webhooks_repository.t;
    sha : string;
    user : Terrat_github_webhooks_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

module Labels = struct
  type t = Terrat_github_webhooks_label.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Requested_reviewers = struct
  module Items = struct
    type t =
      | User of Terrat_github_webhooks_user.t
      | Team of Terrat_github_webhooks_team.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> User v) (Terrat_github_webhooks_user.of_yojson v));
           (fun v -> map (fun v -> Team v) (Terrat_github_webhooks_team.of_yojson v));
         ])

    let to_yojson = function
      | User v -> Terrat_github_webhooks_user.to_yojson v
      | Team v -> Terrat_github_webhooks_team.to_yojson v
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Requested_teams = struct
  type t = Terrat_github_webhooks_team.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module State = struct
  let t_of_yojson = function
    | `String "open" -> Ok "open"
    | `String "closed" -> Ok "closed"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  links_ : Links_.t; [@key "_links"]
  active_lock_reason : string option;
  assignee : Terrat_github_webhooks_user.t option; [@default None]
  assignees : Assignees.t;
  author_association : string;
  auto_merge : Terrat_github_webhooks_auto_merge.t option; [@default None]
  base : Base.t;
  body : string;
  closed_at : string option;
  comments_url : string;
  commits_url : string;
  created_at : string;
  diff_url : string;
  draft : bool;
  head : Head.t;
  html_url : string;
  id : int;
  issue_url : string;
  labels : Labels.t;
  locked : bool;
  merge_commit_sha : string option;
  merged_at : string option;
  milestone : Terrat_github_webhooks_milestone.t option; [@default None]
  node_id : string;
  number : int;
  patch_url : string;
  requested_reviewers : Requested_reviewers.t;
  requested_teams : Requested_teams.t;
  review_comment_url : string;
  review_comments_url : string;
  state : State.t;
  statuses_url : string;
  title : string;
  updated_at : string;
  url : string;
  user : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
