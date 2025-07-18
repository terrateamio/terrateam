module PostApiV4ProjectsIdMergeRequests = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4ProjectsIdMergeRequests.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Conflict = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Conflict
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequests = struct
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

    module Iids = struct
      type t = int list [@@deriving show, eq]
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
      iids : Iids.t option; [@default None]
      in_ : string option; [@default None] [@key "in"]
      labels : Labels.t option; [@default None]
      merge_user_id : int option; [@default None]
      merge_user_username : string option; [@default None]
      milestone : string option; [@default None]
      my_reaction_emoji : string option; [@default None]
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

  let url = "/api/v4/projects/{id}/merge_requests"

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
           ("iids", Var (params.iids, Option (Array Int)));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsEventableIdResourceMilestoneEvents = struct
  module Parameters = struct
    type t = {
      eventable_id : int;
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{eventable_id}/resource_milestone_events"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("eventable_id", Var (params.eventable_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsEventableIdResourceMilestoneEventsEventId = struct
  module Parameters = struct
    type t = {
      event_id : string;
      eventable_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url =
    "/api/v4/projects/{id}/merge_requests/{eventable_id}/resource_milestone_events/{event_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("event_id", Var (params.event_id, String));
           ("eventable_id", Var (params.eventable_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdMergeRequestsMergeRequestIid = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Precondition_failed = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      | `Precondition_failed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("412", fun _ -> Ok `Precondition_failed);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIid = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PutApiV4ProjectsIdMergeRequestsMergeRequestIid.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Conflict = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      | `Conflict
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIid = struct
  module Parameters = struct
    type t = {
      id : string;
      include_diverged_commits_count : bool option; [@default None]
      include_rebase_in_progress : bool option; [@default None]
      merge_request_iid : int;
      render_html : bool option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Gitlabc_components.API_Entities_MergeRequest.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct end

    type t =
      [ `OK of OK.t
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("render_html", Var (params.render_html, Option Bool));
           ( "include_diverged_commits_count",
             Var (params.include_diverged_commits_count, Option Bool) );
           ("include_rebase_in_progress", Var (params.include_rebase_in_progress, Option Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidAddSpentTime = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidAddSpentTime.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/add_spent_time"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidApprovalState = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/approval_state"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidApprovals = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidApprovals.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/approvals"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidApprovals = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/approvals"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int)); ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidApprove = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidApprove.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/approve"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int)); ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidAwardEmoji.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/award_emoji"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int)); ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdMergeRequestsMergeRequestIidAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidCancelMergeWhenPipelineSucceeds = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Method_not_allowed = struct end
    module Not_acceptable = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      | `Method_not_allowed
      | `Not_acceptable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("405", fun _ -> Ok `Method_not_allowed);
        ("406", fun _ -> Ok `Not_acceptable);
      ]
  end

  let url =
    "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/cancel_merge_when_pipeline_succeeds"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidChanges = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      unidiff : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/changes"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("unidiff", Var (params.unidiff, Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidClosesIssues = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/closes_issues"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidCommits = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/commits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdMergeRequestsMergeRequestIidContextCommits = struct
  module Parameters = struct
    module Commits = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      commits : Commits.t;
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/context_commits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("commits", Var (params.commits, Array String)) ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidContextCommits = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidContextCommits.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/context_commits"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidContextCommits = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/context_commits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidDiffs = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
      unidiff : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Gitlabc_components.API_Entities_Diff.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK of OK.t
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/diffs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("unidiff", Var (params.unidiff, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotes = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotes.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotes = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesBulkPublish = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes/bulk_publish"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesDraftNoteId = struct
  module Parameters = struct
    type t = {
      draft_note_id : int;
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes/{draft_note_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("draft_note_id", Var (params.draft_note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesDraftNoteId = struct
  module Parameters = struct
    type t = {
      draft_note_id : int;
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t =
      Gitlabc_components.PutApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesDraftNoteId.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes/{draft_note_id}"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("draft_note_id", Var (params.draft_note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesDraftNoteId = struct
  module Parameters = struct
    type t = {
      draft_note_id : int;
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes/{draft_note_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("draft_note_id", Var (params.draft_note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIidDraftNotesDraftNoteIdPublish = struct
  module Parameters = struct
    type t = {
      draft_note_id : int;
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/draft_notes/{draft_note_id}/publish"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("draft_note_id", Var (params.draft_note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIidMerge = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Gitlabc_components.API_Entities_MergeRequest.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end
    module Method_not_allowed = struct end
    module Conflict = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK of OK.t
      | `Bad_request
      | `Unauthorized
      | `Not_found
      | `Method_not_allowed
      | `Conflict
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
        ("405", fun _ -> Ok `Method_not_allowed);
        ("409", fun _ -> Ok `Conflict);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/merge"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidMergeRef = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "created_at" -> Ok "created_at"
        | `String "updated_at" -> Ok "updated_at"
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

    type t = {
      id : string;
      merge_request_iid : int;
      order_by : Order_by.t option; [@default None]
      sort : Sort.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end

    type t =
      [ `OK
      | `Bad_request
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("400", fun _ -> Ok `Bad_request) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/merge_ref"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("sort", Var (params.sort, Option String));
           ("order_by", Var (params.order_by, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNotesId = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = { body : string } [@@deriving make, yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module OK = struct end

    module Created = struct
      type t = { id : int } [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Not_found = struct end

    type t =
      [ `OK
      | `Created of Created.t
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidNotes = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Gitlabc_components.API_Entities_Note.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct end

    type t =
      [ `OK of OK.t
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNotesId = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes/{note_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNotesId = struct
  module Parameters = struct
    type t = {
      body : string;
      id : string;
      merge_request_iid : int;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes/{note_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("body", Var (params.body, String)) ])
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNotesId = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Gitlabc_components.API_Entities_Note.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct end

    type t =
      [ `OK of OK.t
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes/{note_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNoteIdAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
      name : string;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct
      type t = Gitlabc_components.API_Entities_AwardEmoji.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `Created of Created.t
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes/{note_id}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("name", Var (params.name, String)) ])
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNoteIdAwardEmoji = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
      note_id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes/{note_id}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNoteIdAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      merge_request_iid : int;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes/{note_id}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNoteIdAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      id : int;
      merge_request_iid : int;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url =
    "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/notes/{note_id}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidParticipants = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/participants"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidPipelines = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidPipelines.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Method_not_allowed = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      | `Method_not_allowed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("405", fun _ -> Ok `Method_not_allowed);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/pipelines"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidPipelines = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/pipelines"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidRawDiffs = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/raw_diffs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIidRebase = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PutApiV4ProjectsIdMergeRequestsMergeRequestIidRebase.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Conflict = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      | `Conflict
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/rebase"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidRelatedIssues = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/related_issues"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdMergeRequestsMergeRequestIidResetApprovals = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/reset_approvals"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int)); ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidResetSpentTime = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/reset_spent_time"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidResetTimeEstimate = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/reset_time_estimate"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidReviewers = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/reviewers"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidTimeEstimate = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4ProjectsIdMergeRequestsMergeRequestIidTimeEstimate.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/time_estimate"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidTimeStats = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/time_stats"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdMergeRequestsMergeRequestIidUnapprove = struct
  module Parameters = struct
    type t = {
      id : int;
      merge_request_iid : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/unapprove"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int)); ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidVersions = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/versions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdMergeRequestsMergeRequestIidVersionsVersionId = struct
  module Parameters = struct
    type t = {
      id : string;
      merge_request_iid : int;
      unidiff : bool; [@default false]
      version_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/merge_requests/{merge_request_iid}/versions/{version_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("merge_request_iid", Var (params.merge_request_iid, Int));
           ("version_id", Var (params.version_id, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("unidiff", Var (params.unidiff, Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end
