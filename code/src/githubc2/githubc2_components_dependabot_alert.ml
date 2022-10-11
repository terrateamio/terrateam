module Primary = struct
  type t = {
    created_at : string;
    dependency : Githubc2_components_dependabot_alert_dependency.t;
    dismissed_at : string option;
    dismissed_by : Githubc2_components_nullable_simple_user.t option;
    dismissed_comment : string option;
    dismissed_reason : Githubc2_components_dependabot_alert_dismissed_reason.t;
    fixed_at : string option;
    html_url : string;
    number : int;
    security_advisory : Githubc2_components_dependabot_alert_security_advisory.t;
    security_vulnerability : Githubc2_components_dependabot_alert_security_vulnerability.t;
    state : Githubc2_components_dependabot_alert_state.t;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
