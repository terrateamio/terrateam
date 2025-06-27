module GetApiV4GroupsIdMergeRequests = struct
  module Parameters = struct
    module Approved = struct
      let t_of_yojson = function
        | `String "yes" -> Ok "yes"
        | `String "no" -> Ok "no"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Assignee_username = struct
      type t = string list [@@deriving show, eq]
    end

    module Labels = struct
      type t = string list [@@deriving show, eq]
    end

    module Not_assignee_username_ = struct
      type t = string list [@@deriving show, eq]
    end

    module Not_labels_ = struct
      type t = string list [@@deriving show, eq]
    end

    module Order_by = struct
      let t_of_yojson = function
        | `String "created_at" -> Ok "created_at"
        | `String "label_priority" -> Ok "label_priority"
        | `String "milestone_due" -> Ok "milestone_due"
        | `String "popularity" -> Ok "popularity"
        | `String "priority" -> Ok "priority"
        | `String "title" -> Ok "title"
        | `String "updated_at" -> Ok "updated_at"
        | `String "merged_at" -> Ok "merged_at"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Scope = struct
      let t_of_yojson = function
        | `String "created-by-me" -> Ok "created-by-me"
        | `String "assigned-to-me" -> Ok "assigned-to-me"
        | `String "created_by_me" -> Ok "created_by_me"
        | `String "assigned_to_me" -> Ok "assigned_to_me"
        | `String "all" -> Ok "all"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module State = struct
      let t_of_yojson = function
        | `String "opened" -> Ok "opened"
        | `String "closed" -> Ok "closed"
        | `String "locked" -> Ok "locked"
        | `String "merged" -> Ok "merged"
        | `String "all" -> Ok "all"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module View = struct
      let t_of_yojson = function
        | `String "simple" -> Ok "simple"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Wip = struct
      let t_of_yojson = function
        | `String "yes" -> Ok "yes"
        | `String "no" -> Ok "no"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      approved : Approved.t option; [@default None]
      approved_by_ids : string option; [@default None]
      approved_by_usernames : string option; [@default None]
      approver_ids : string option; [@default None]
      assignee_id : int option; [@default None]
      assignee_username : Assignee_username.t option; [@default None]
      author_id : int option; [@default None]
      author_username : string option; [@default None]
      created_after : string option; [@default None]
      created_before : string option; [@default None]
      deployed_after : string option; [@default None]
      deployed_before : string option; [@default None]
      environment : string option; [@default None]
      id : string;
      in_ : string option; [@default None] [@key "in"]
      labels : Labels.t option; [@default None]
      merge_user_id : int option; [@default None]
      merge_user_username : string option; [@default None]
      milestone : string option; [@default None]
      my_reaction_emoji : string option; [@default None]
      non_archived : bool; [@default true]
      not_assignee_id_ : int option; [@default None] [@key "not[assignee_id]"]
      not_assignee_username_ : Not_assignee_username_.t option;
          [@default None] [@key "not[assignee_username]"]
      not_author_id_ : int option; [@default None] [@key "not[author_id]"]
      not_author_username_ : string option; [@default None] [@key "not[author_username]"]
      not_labels_ : Not_labels_.t option; [@default None] [@key "not[labels]"]
      not_milestone_ : string option; [@default None] [@key "not[milestone]"]
      not_my_reaction_emoji_ : string option; [@default None] [@key "not[my_reaction_emoji]"]
      not_reviewer_id_ : int option; [@default None] [@key "not[reviewer_id]"]
      not_reviewer_username_ : string option; [@default None] [@key "not[reviewer_username]"]
      order_by : Order_by.t; [@default "created_at"]
      page : int; [@default 1]
      per_page : int; [@default 20]
      reviewer_id : int option; [@default None]
      reviewer_username : string option; [@default None]
      scope : Scope.t option; [@default None]
      search : string option; [@default None]
      sort : Sort.t; [@default "desc"]
      source_branch : string option; [@default None]
      source_project_id : int option; [@default None]
      state : State.t; [@default "all"]
      target_branch : string option; [@default None]
      updated_after : string option; [@default None]
      updated_before : string option; [@default None]
      view : View.t option; [@default None]
      wip : Wip.t option; [@default None]
      with_labels_details : bool; [@default false]
      with_merge_status_recheck : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/groups/{id}/merge_requests"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("author_id", Var (params.author_id, Option Int));
           ("author_username", Var (params.author_username, Option String));
           ("assignee_id", Var (params.assignee_id, Option Int));
           ("assignee_username", Var (params.assignee_username, Option (Array String)));
           ("reviewer_username", Var (params.reviewer_username, Option String));
           ("labels", Var (params.labels, Option (Array String)));
           ("milestone", Var (params.milestone, Option String));
           ("my_reaction_emoji", Var (params.my_reaction_emoji, Option String));
           ("reviewer_id", Var (params.reviewer_id, Option Int));
           ("state", Var (params.state, String));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("with_labels_details", Var (params.with_labels_details, Bool));
           ("with_merge_status_recheck", Var (params.with_merge_status_recheck, Bool));
           ("created_after", Var (params.created_after, Option String));
           ("created_before", Var (params.created_before, Option String));
           ("updated_after", Var (params.updated_after, Option String));
           ("updated_before", Var (params.updated_before, Option String));
           ("view", Var (params.view, Option String));
           ("scope", Var (params.scope, Option String));
           ("source_branch", Var (params.source_branch, Option String));
           ("source_project_id", Var (params.source_project_id, Option Int));
           ("target_branch", Var (params.target_branch, Option String));
           ("search", Var (params.search, Option String));
           ("in", Var (params.in_, Option String));
           ("wip", Var (params.wip, Option String));
           ("not[author_id]", Var (params.not_author_id_, Option Int));
           ("not[author_username]", Var (params.not_author_username_, Option String));
           ("not[assignee_id]", Var (params.not_assignee_id_, Option Int));
           ("not[assignee_username]", Var (params.not_assignee_username_, Option (Array String)));
           ("not[reviewer_username]", Var (params.not_reviewer_username_, Option String));
           ("not[labels]", Var (params.not_labels_, Option (Array String)));
           ("not[milestone]", Var (params.not_milestone_, Option String));
           ("not[my_reaction_emoji]", Var (params.not_my_reaction_emoji_, Option String));
           ("not[reviewer_id]", Var (params.not_reviewer_id_, Option Int));
           ("deployed_before", Var (params.deployed_before, Option String));
           ("deployed_after", Var (params.deployed_after, Option String));
           ("environment", Var (params.environment, Option String));
           ("approved", Var (params.approved, Option String));
           ("merge_user_id", Var (params.merge_user_id, Option Int));
           ("merge_user_username", Var (params.merge_user_username, Option String));
           ("approver_ids", Var (params.approver_ids, Option String));
           ("approved_by_ids", Var (params.approved_by_ids, Option String));
           ("approved_by_usernames", Var (params.approved_by_usernames, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("non_archived", Var (params.non_archived, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end
