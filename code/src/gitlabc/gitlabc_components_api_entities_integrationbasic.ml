module Primary = struct
  type t = {
    active : bool option; [@default None]
    alert_events : bool option; [@default None]
    comment_on_event_enabled : bool option; [@default None]
    commit_events : bool option; [@default None]
    confidential_issues_events : bool option; [@default None]
    confidential_note_events : bool option; [@default None]
    created_at : string option; [@default None]
    deployment_events : bool option; [@default None]
    id : int option; [@default None]
    incident_events : bool option; [@default None]
    inherited : bool option; [@default None]
    issues_events : bool option; [@default None]
    job_events : bool option; [@default None]
    merge_requests_events : bool option; [@default None]
    note_events : bool option; [@default None]
    pipeline_events : bool option; [@default None]
    push_events : bool option; [@default None]
    slug : int option; [@default None]
    tag_push_events : bool option; [@default None]
    title : string option; [@default None]
    updated_at : string option; [@default None]
    vulnerability_events : bool option; [@default None]
    wiki_page_events : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
