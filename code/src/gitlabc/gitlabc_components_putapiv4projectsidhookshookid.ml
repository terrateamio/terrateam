module Primary = struct
  module Branch_filter_strategy = struct
    let t_of_yojson = function
      | `String "wildcard" -> Ok "wildcard"
      | `String "regex" -> Ok "regex"
      | `String "all_branches" -> Ok "all_branches"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Custom_headers = struct
    module Items = struct
      module Primary = struct
        type t = {
          key : string;
          value : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Url_variables = struct
    module Items = struct
      module Primary = struct
        type t = {
          key : string;
          value : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    branch_filter_strategy : Branch_filter_strategy.t option; [@default None]
    confidential_issues_events : bool option; [@default None]
    confidential_note_events : bool option; [@default None]
    custom_headers : Custom_headers.t option; [@default None]
    custom_webhook_template : string option; [@default None]
    deployment_events : bool option; [@default None]
    description : string option; [@default None]
    emoji_events : bool option; [@default None]
    enable_ssl_verification : bool option; [@default None]
    feature_flag_events : bool option; [@default None]
    issues_events : bool option; [@default None]
    job_events : bool option; [@default None]
    merge_requests_events : bool option; [@default None]
    name : string option; [@default None]
    note_events : bool option; [@default None]
    pipeline_events : bool option; [@default None]
    push_events : bool option; [@default None]
    push_events_branch_filter : string option; [@default None]
    releases_events : bool option; [@default None]
    resource_access_token_events : bool option; [@default None]
    tag_push_events : bool option; [@default None]
    token : string option; [@default None]
    url : string option; [@default None]
    url_variables : Url_variables.t option; [@default None]
    vulnerability_events : bool option; [@default None]
    wiki_page_events : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
