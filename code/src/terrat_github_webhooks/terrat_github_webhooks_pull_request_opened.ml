module Action = struct
  let t_of_yojson = function
    | `String "opened" -> Ok "opened"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Pull_request_ = struct
  module All_of = struct
    module Primary = struct
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

      module Merged_by = struct
        type t = unit [@@deriving yojson { strict = false; meta = true }, show, eq]
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
        active_lock_reason : string option; [@default None]
        additions : int;
        assignee : Terrat_github_webhooks_user.t option; [@default None]
        assignees : Assignees.t;
        author_association : string;
        auto_merge : Terrat_github_webhooks_auto_merge.t option; [@default None]
        base : Base.t;
        body : string option; [@default None]
        changed_files : int;
        closed_at : string option; [@default None]
        comments : int;
        comments_url : string;
        commits : int;
        commits_url : string;
        created_at : string;
        deletions : int;
        diff_url : string;
        draft : bool;
        head : Head.t;
        html_url : string;
        id : int;
        issue_url : string;
        labels : Labels.t;
        locked : bool;
        maintainer_can_modify : bool;
        merge_commit_sha : string option; [@default None]
        mergeable : bool option; [@default None]
        mergeable_state : string;
        merged : bool option; [@default None]
        merged_at : string option; [@default None]
        merged_by : Merged_by.t;
        milestone : Terrat_github_webhooks_milestone.t option; [@default None]
        node_id : string;
        number : int;
        patch_url : string;
        rebaseable : bool option; [@default None]
        requested_reviewers : Requested_reviewers.t;
        requested_teams : Requested_teams.t;
        review_comment_url : string;
        review_comments : int;
        review_comments_url : string;
        state : State.t;
        statuses_url : string;
        title : string;
        updated_at : string;
        url : string;
        user : Terrat_github_webhooks_user.t;
      }
      [@@deriving yojson { strict = false; meta = true }, make, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
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

      module Merged_by = struct
        type t = unit [@@deriving yojson { strict = false; meta = true }, show, eq]
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
        active_lock_reason : string option; [@default None]
        additions : int;
        assignee : Terrat_github_webhooks_user.t option; [@default None]
        assignees : Assignees.t;
        author_association : string;
        auto_merge : Terrat_github_webhooks_auto_merge.t option; [@default None]
        base : Base.t;
        body : string option; [@default None]
        changed_files : int;
        closed_at : string option; [@default None]
        comments : int;
        comments_url : string;
        commits : int;
        commits_url : string;
        created_at : string;
        deletions : int;
        diff_url : string;
        draft : bool;
        head : Head.t;
        html_url : string;
        id : int;
        issue_url : string;
        labels : Labels.t;
        locked : bool;
        maintainer_can_modify : bool;
        merge_commit_sha : string option; [@default None]
        mergeable : bool option; [@default None]
        mergeable_state : string;
        merged : bool option; [@default None]
        merged_at : string option; [@default None]
        merged_by : Merged_by.t;
        milestone : Terrat_github_webhooks_milestone.t option; [@default None]
        node_id : string;
        number : int;
        patch_url : string;
        rebaseable : bool option; [@default None]
        requested_reviewers : Requested_reviewers.t;
        requested_teams : Requested_teams.t;
        review_comment_url : string;
        review_comments : int;
        review_comments_url : string;
        state : State.t;
        statuses_url : string;
        title : string;
        updated_at : string;
        url : string;
        user : Terrat_github_webhooks_user.t;
      }
      [@@deriving yojson { strict = false; meta = true }, make, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

type t = {
  action : Action.t;
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  number : int;
  organization : Terrat_github_webhooks_organization.t option; [@default None]
  pull_request : Pull_request_.t;
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
