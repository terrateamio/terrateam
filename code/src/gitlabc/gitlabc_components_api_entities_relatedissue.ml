module Primary = struct
  module Links_ = struct
    module Primary = struct
      type t = {
        award_emoji : string option; [@default None]
        closed_as_duplicate_of : string option; [@default None]
        notes : string option; [@default None]
        project : string option; [@default None]
        self : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Labels = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    links_ : Links_.t option; [@default None] [@key "_links"]
    assignee : Gitlabc_components_api_entities_userbasic.t option; [@default None]
    assignees : Gitlabc_components_api_entities_userbasic.t option; [@default None]
    author : Gitlabc_components_api_entities_userbasic.t option; [@default None]
    blocking_issues_count : string option; [@default None]
    closed_at : string option; [@default None]
    closed_by : Gitlabc_components_api_entities_userbasic.t option; [@default None]
    confidential : bool option; [@default None]
    created_at : string option; [@default None]
    description : string option; [@default None]
    discussion_locked : bool option; [@default None]
    downvotes : string option; [@default None]
    due_date : string option; [@default None]
    epic : Gitlabc_components_epicbaseentity.t option; [@default None]
    epic_iid : string option; [@default None]
    has_tasks : string option; [@default None]
    health_status : string option; [@default None]
    id : int option; [@default None]
    iid : int option; [@default None]
    imported : string option; [@default None]
    imported_from : string option; [@default None]
    issue_link_id : string option; [@default None]
    issue_type : string option; [@default None]
    iteration : Gitlabc_components_api_entities_iteration.t option; [@default None]
    labels : Labels.t option; [@default None]
    link_created_at : string option; [@default None]
    link_type : string option; [@default None]
    link_updated_at : string option; [@default None]
    merge_requests_count : string option; [@default None]
    milestone : Gitlabc_components_api_entities_milestone.t option; [@default None]
    moved_to_id : string option; [@default None]
    project_id : int option; [@default None]
    references : Gitlabc_components_api_entities_issuablereferences.t option; [@default None]
    service_desk_reply_to : string option; [@default None]
    severity : string option; [@default None]
    state : string option; [@default None]
    subscribed : string option; [@default None]
    task_completion_status : string option; [@default None]
    task_status : string option; [@default None]
    time_stats : Gitlabc_components_api_entities_issuabletimestats.t option; [@default None]
    title : string option; [@default None]
    type_ : string option; [@default None] [@key "type"]
    updated_at : string option; [@default None]
    upvotes : string option; [@default None]
    user_notes_count : string option; [@default None]
    web_url : string option; [@default None]
    weight : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
