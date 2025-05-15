module Primary = struct
  module Validity = struct
    let t_of_yojson = function
      | `String "active" -> Ok "active"
      | `String "inactive" -> Ok "inactive"
      | `String "unknown" -> Ok "unknown"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string option; [@default None]
    html_url : string option; [@default None]
    locations_url : string option; [@default None]
    multi_repo : bool option; [@default None]
    number : int option; [@default None]
    publicly_leaked : bool option; [@default None]
    push_protection_bypass_request_comment : string option; [@default None]
    push_protection_bypass_request_html_url : string option; [@default None]
    push_protection_bypass_request_reviewer : Githubc2_components_nullable_simple_user.t option;
        [@default None]
    push_protection_bypass_request_reviewer_comment : string option; [@default None]
    push_protection_bypassed : bool option; [@default None]
    push_protection_bypassed_at : string option; [@default None]
    push_protection_bypassed_by : Githubc2_components_nullable_simple_user.t option; [@default None]
    resolution : Githubc2_components_secret_scanning_alert_resolution_webhook.t option;
        [@default None]
    resolution_comment : string option; [@default None]
    resolved_at : string option; [@default None]
    resolved_by : Githubc2_components_nullable_simple_user.t option; [@default None]
    secret_type : string option; [@default None]
    secret_type_display_name : string option; [@default None]
    updated_at : string option; [@default None]
    url : string option; [@default None]
    validity : Validity.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
