module All_of = struct
  module Primary = struct
    module Links_ = struct
      module Primary = struct
        type t = {
          comments : Githubc2_components_link.t;
          commits : Githubc2_components_link.t;
          html : Githubc2_components_link.t;
          issue : Githubc2_components_link.t;
          review_comment : Githubc2_components_link.t;
          review_comments : Githubc2_components_link.t;
          self : Githubc2_components_link.t;
          statuses : Githubc2_components_link.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Assignees = struct
      type t = Githubc2_components_simple_user.t list
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Base = struct
      module Primary = struct
        type t = {
          label : string;
          ref_ : string; [@key "ref"]
          repo : Githubc2_components_repository.t;
          sha : string;
          user : Githubc2_components_simple_user.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Head = struct
      module Primary = struct
        type t = {
          label : string;
          ref_ : string; [@key "ref"]
          repo : Githubc2_components_repository.t;
          sha : string;
          user : Githubc2_components_simple_user.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Labels = struct
      module Items = struct
        module Primary = struct
          type t = {
            color : string;
            default : bool;
            description : string option; [@default None]
            id : int64;
            name : string;
            node_id : string;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Merge_commit_message = struct
      let t_of_yojson = function
        | `String "PR_BODY" -> Ok "PR_BODY"
        | `String "PR_TITLE" -> Ok "PR_TITLE"
        | `String "BLANK" -> Ok "BLANK"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Merge_commit_title = struct
      let t_of_yojson = function
        | `String "PR_TITLE" -> Ok "PR_TITLE"
        | `String "MERGE_MESSAGE" -> Ok "MERGE_MESSAGE"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Requested_reviewers = struct
      type t = Githubc2_components_simple_user.t list
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Requested_teams = struct
      type t = Githubc2_components_team_simple.t list
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Squash_merge_commit_message = struct
      let t_of_yojson = function
        | `String "PR_BODY" -> Ok "PR_BODY"
        | `String "COMMIT_MESSAGES" -> Ok "COMMIT_MESSAGES"
        | `String "BLANK" -> Ok "BLANK"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Squash_merge_commit_title = struct
      let t_of_yojson = function
        | `String "PR_TITLE" -> Ok "PR_TITLE"
        | `String "COMMIT_OR_PR_TITLE" -> Ok "COMMIT_OR_PR_TITLE"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
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
      allow_auto_merge : bool; [@default false]
      allow_update_branch : bool option; [@default None]
      assignee : Githubc2_components_nullable_simple_user.t option; [@default None]
      assignees : Assignees.t option; [@default None]
      author_association : Githubc2_components_author_association.t;
      auto_merge : Githubc2_components_auto_merge.t option; [@default None]
      base : Base.t;
      body : string option; [@default None]
      changed_files : int;
      closed_at : string option; [@default None]
      comments : int;
      comments_url : string;
      commits : int;
      commits_url : string;
      created_at : string;
      delete_branch_on_merge : bool; [@default false]
      deletions : int;
      diff_url : string;
      draft : bool option; [@default None]
      head : Head.t;
      html_url : string;
      id : int64;
      issue_url : string;
      labels : Labels.t;
      locked : bool;
      maintainer_can_modify : bool;
      merge_commit_message : Merge_commit_message.t option; [@default None]
      merge_commit_sha : string option; [@default None]
      merge_commit_title : Merge_commit_title.t option; [@default None]
      mergeable : bool option; [@default None]
      mergeable_state : string;
      merged : bool;
      merged_at : string option; [@default None]
      merged_by : Githubc2_components_nullable_simple_user.t option; [@default None]
      milestone : Githubc2_components_nullable_milestone.t option; [@default None]
      node_id : string;
      number : int;
      patch_url : string;
      rebaseable : bool option; [@default None]
      requested_reviewers : Requested_reviewers.t option; [@default None]
      requested_teams : Requested_teams.t option; [@default None]
      review_comment_url : string;
      review_comments : int;
      review_comments_url : string;
      squash_merge_commit_message : Squash_merge_commit_message.t option; [@default None]
      squash_merge_commit_title : Squash_merge_commit_title.t option; [@default None]
      state : State.t;
      statuses_url : string;
      title : string;
      updated_at : string;
      url : string;
      use_squash_pr_title_as_default : bool; [@default false]
      user : Githubc2_components_simple_user.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module T = struct
  module Primary = struct
    module Links_ = struct
      module Primary = struct
        type t = {
          comments : Githubc2_components_link.t;
          commits : Githubc2_components_link.t;
          html : Githubc2_components_link.t;
          issue : Githubc2_components_link.t;
          review_comment : Githubc2_components_link.t;
          review_comments : Githubc2_components_link.t;
          self : Githubc2_components_link.t;
          statuses : Githubc2_components_link.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Assignees = struct
      type t = Githubc2_components_simple_user.t list
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Base = struct
      module Primary = struct
        type t = {
          label : string;
          ref_ : string; [@key "ref"]
          repo : Githubc2_components_repository.t;
          sha : string;
          user : Githubc2_components_simple_user.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Head = struct
      module Primary = struct
        type t = {
          label : string;
          ref_ : string; [@key "ref"]
          repo : Githubc2_components_repository.t;
          sha : string;
          user : Githubc2_components_simple_user.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Labels = struct
      module Items = struct
        module Primary = struct
          type t = {
            color : string;
            default : bool;
            description : string option; [@default None]
            id : int64;
            name : string;
            node_id : string;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Merge_commit_message = struct
      let t_of_yojson = function
        | `String "PR_BODY" -> Ok "PR_BODY"
        | `String "PR_TITLE" -> Ok "PR_TITLE"
        | `String "BLANK" -> Ok "BLANK"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Merge_commit_title = struct
      let t_of_yojson = function
        | `String "PR_TITLE" -> Ok "PR_TITLE"
        | `String "MERGE_MESSAGE" -> Ok "MERGE_MESSAGE"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Requested_reviewers = struct
      type t = Githubc2_components_simple_user.t list
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Requested_teams = struct
      type t = Githubc2_components_team_simple.t list
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Squash_merge_commit_message = struct
      let t_of_yojson = function
        | `String "PR_BODY" -> Ok "PR_BODY"
        | `String "COMMIT_MESSAGES" -> Ok "COMMIT_MESSAGES"
        | `String "BLANK" -> Ok "BLANK"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Squash_merge_commit_title = struct
      let t_of_yojson = function
        | `String "PR_TITLE" -> Ok "PR_TITLE"
        | `String "COMMIT_OR_PR_TITLE" -> Ok "COMMIT_OR_PR_TITLE"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
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
      allow_auto_merge : bool; [@default false]
      allow_update_branch : bool option; [@default None]
      assignee : Githubc2_components_nullable_simple_user.t option; [@default None]
      assignees : Assignees.t option; [@default None]
      author_association : Githubc2_components_author_association.t;
      auto_merge : Githubc2_components_auto_merge.t option; [@default None]
      base : Base.t;
      body : string option; [@default None]
      changed_files : int;
      closed_at : string option; [@default None]
      comments : int;
      comments_url : string;
      commits : int;
      commits_url : string;
      created_at : string;
      delete_branch_on_merge : bool; [@default false]
      deletions : int;
      diff_url : string;
      draft : bool option; [@default None]
      head : Head.t;
      html_url : string;
      id : int64;
      issue_url : string;
      labels : Labels.t;
      locked : bool;
      maintainer_can_modify : bool;
      merge_commit_message : Merge_commit_message.t option; [@default None]
      merge_commit_sha : string option; [@default None]
      merge_commit_title : Merge_commit_title.t option; [@default None]
      mergeable : bool option; [@default None]
      mergeable_state : string;
      merged : bool;
      merged_at : string option; [@default None]
      merged_by : Githubc2_components_nullable_simple_user.t option; [@default None]
      milestone : Githubc2_components_nullable_milestone.t option; [@default None]
      node_id : string;
      number : int;
      patch_url : string;
      rebaseable : bool option; [@default None]
      requested_reviewers : Requested_reviewers.t option; [@default None]
      requested_teams : Requested_teams.t option; [@default None]
      review_comment_url : string;
      review_comments : int;
      review_comments_url : string;
      squash_merge_commit_message : Squash_merge_commit_message.t option; [@default None]
      squash_merge_commit_title : Squash_merge_commit_title.t option; [@default None]
      state : State.t;
      statuses_url : string;
      title : string;
      updated_at : string;
      url : string;
      use_squash_pr_title_as_default : bool; [@default false]
      user : Githubc2_components_simple_user.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

let of_yojson json =
  let open CCResult in
  flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
