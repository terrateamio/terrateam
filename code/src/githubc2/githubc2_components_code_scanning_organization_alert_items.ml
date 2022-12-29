module Primary = struct
  type t = {
    created_at : string;
    dismissed_at : string option;
    dismissed_by : Githubc2_components_nullable_simple_user.t option;
    dismissed_comment : string option; [@default None]
    dismissed_reason : Githubc2_components_code_scanning_alert_dismissed_reason.t;
    fixed_at : string option; [@default None]
    html_url : string;
    instances_url : string;
    most_recent_instance : Githubc2_components_code_scanning_alert_instance.t;
    number : int;
    repository : Githubc2_components_simple_repository.t;
    rule : Githubc2_components_code_scanning_alert_rule.t;
    state : Githubc2_components_code_scanning_alert_state.t;
    tool : Githubc2_components_code_scanning_analysis_tool.t;
    updated_at : string option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
