type t = {
  branches_to_be_notified : string option; [@default None]
  confidential_issues_events : bool option; [@default None]
  confidential_note_events : bool option; [@default None]
  hostname : string option; [@default None]
  incident_events : bool option; [@default None]
  issues_events : bool option; [@default None]
  merge_requests_events : bool option; [@default None]
  note_events : bool option; [@default None]
  notify_only_broken_pipelines : bool option; [@default None]
  pipeline_events : bool option; [@default None]
  push_events : bool option; [@default None]
  room : string;
  tag_push_events : bool option; [@default None]
  token : string;
  use_inherited_settings : bool option; [@default None]
  vulnerability_events : bool option; [@default None]
  wiki_page_events : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
