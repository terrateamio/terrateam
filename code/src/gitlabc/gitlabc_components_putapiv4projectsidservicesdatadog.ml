module Primary = struct
  type t = {
    api_key : string;
    api_url : string option; [@default None]
    archive_trace_events : bool option; [@default None]
    build_events : bool option; [@default None]
    datadog_ci_visibility : bool option; [@default None]
    datadog_env : string option; [@default None]
    datadog_service : string option; [@default None]
    datadog_site : string option; [@default None]
    datadog_tags : string option; [@default None]
    merge_requests_events : bool option; [@default None]
    note_events : bool option; [@default None]
    pipeline_events : bool option; [@default None]
    project_events : bool option; [@default None]
    push_events : bool option; [@default None]
    subgroup_events : bool option; [@default None]
    tag_push_events : bool option; [@default None]
    use_inherited_settings : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
