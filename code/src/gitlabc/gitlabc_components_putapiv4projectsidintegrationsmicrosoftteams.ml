module Primary = struct
  type t = {
    branches_to_be_notified : string option; [@default None]
    confidential_issues_events : bool option; [@default None]
    confidential_note_events : bool option; [@default None]
    issues_events : bool option; [@default None]
    merge_requests_events : bool option; [@default None]
    note_events : bool option; [@default None]
    notify_only_broken_pipelines : bool option; [@default None]
    pipeline_events : bool option; [@default None]
    push_events : bool option; [@default None]
    tag_push_events : bool option; [@default None]
    use_inherited_settings : bool option; [@default None]
    webhook : string;
    wiki_page_events : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
