module Primary = struct
  type t = {
    created_at : string;
    dismissed_at : string option;
    dismissed_by : Githubc2_components_nullable_simple_user.t option;
    dismissed_reason : Githubc2_components_code_scanning_alert_dismissed_reason.t option;
    html_url : string;
    instances_url : string;
    most_recent_instance : Githubc2_components_code_scanning_alert_instance.t;
    number : int;
    rule : Githubc2_components_code_scanning_alert_rule_summary.t;
    state : Githubc2_components_code_scanning_alert_state.t;
    tool : Githubc2_components_code_scanning_analysis_tool.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)