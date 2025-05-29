module Primary = struct
  module Custom_headers = struct
    module Items = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Url_variables = struct
    module Items = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    alert_status : string option; [@default None]
    branch_filter_strategy : string option; [@default None]
    confidential_issues_events : bool option; [@default None]
    confidential_note_events : bool option; [@default None]
    created_at : string option; [@default None]
    custom_headers : Custom_headers.t option; [@default None]
    custom_webhook_template : string option; [@default None]
    deployment_events : bool option; [@default None]
    description : string option; [@default None]
    disabled_until : string option; [@default None]
    emoji_events : bool option; [@default None]
    enable_ssl_verification : bool option; [@default None]
    feature_flag_events : bool option; [@default None]
    id : string option; [@default None]
    issues_events : bool option; [@default None]
    job_events : bool option; [@default None]
    merge_requests_events : bool option; [@default None]
    name : string option; [@default None]
    note_events : bool option; [@default None]
    pipeline_events : bool option; [@default None]
    project_id : string option; [@default None]
    push_events : bool option; [@default None]
    push_events_branch_filter : string option; [@default None]
    releases_events : bool option; [@default None]
    repository_update_events : bool option; [@default None]
    resource_access_token_events : bool option; [@default None]
    tag_push_events : bool option; [@default None]
    url : string option; [@default None]
    url_variables : Url_variables.t option; [@default None]
    vulnerability_events : bool option; [@default None]
    wiki_page_events : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
