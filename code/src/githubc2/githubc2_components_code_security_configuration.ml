module Primary = struct
  module Advanced_security = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Code_scanning_default_setup_ = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Code_scanning_default_setup_options_ = struct
    module Primary = struct
      module Runner_type = struct
        let t_of_yojson = function
          | `String "standard" -> Ok "standard"
          | `String "labeled" -> Ok "labeled"
          | `String "not_set" -> Ok "not_set"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        runner_label : string option; [@default None]
        runner_type : Runner_type.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Code_scanning_delegated_alert_dismissal = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Dependabot_alerts = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Dependabot_security_updates = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Dependency_graph = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Dependency_graph_autosubmit_action = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Dependency_graph_autosubmit_action_options = struct
    module Primary = struct
      type t = { labeled_runners : bool option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Enforcement = struct
    let t_of_yojson = function
      | `String "enforced" -> Ok "enforced"
      | `String "unenforced" -> Ok "unenforced"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Private_vulnerability_reporting = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Secret_scanning = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Secret_scanning_delegated_alert_dismissal = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Secret_scanning_delegated_bypass = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Secret_scanning_delegated_bypass_options = struct
    module Primary = struct
      module Reviewers = struct
        module Items = struct
          module Primary = struct
            module Reviewer_type = struct
              let t_of_yojson = function
                | `String "TEAM" -> Ok "TEAM"
                | `String "ROLE" -> Ok "ROLE"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            type t = {
              reviewer_id : int;
              reviewer_type : Reviewer_type.t;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { reviewers : Reviewers.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Secret_scanning_generic_secrets = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Secret_scanning_non_provider_patterns = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Secret_scanning_push_protection = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Secret_scanning_validity_checks = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "not_set" -> Ok "not_set"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Target_type = struct
    let t_of_yojson = function
      | `String "global" -> Ok "global"
      | `String "organization" -> Ok "organization"
      | `String "enterprise" -> Ok "enterprise"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    advanced_security : Advanced_security.t option; [@default None]
    code_scanning_default_setup : Code_scanning_default_setup_.t option; [@default None]
    code_scanning_default_setup_options : Code_scanning_default_setup_options_.t option;
        [@default None]
    code_scanning_delegated_alert_dismissal : Code_scanning_delegated_alert_dismissal.t option;
        [@default None]
    created_at : string option; [@default None]
    dependabot_alerts : Dependabot_alerts.t option; [@default None]
    dependabot_security_updates : Dependabot_security_updates.t option; [@default None]
    dependency_graph : Dependency_graph.t option; [@default None]
    dependency_graph_autosubmit_action : Dependency_graph_autosubmit_action.t option;
        [@default None]
    dependency_graph_autosubmit_action_options :
      Dependency_graph_autosubmit_action_options.t option;
        [@default None]
    description : string option; [@default None]
    enforcement : Enforcement.t option; [@default None]
    html_url : string option; [@default None]
    id : int option; [@default None]
    name : string option; [@default None]
    private_vulnerability_reporting : Private_vulnerability_reporting.t option; [@default None]
    secret_scanning : Secret_scanning.t option; [@default None]
    secret_scanning_delegated_alert_dismissal : Secret_scanning_delegated_alert_dismissal.t option;
        [@default None]
    secret_scanning_delegated_bypass : Secret_scanning_delegated_bypass.t option; [@default None]
    secret_scanning_delegated_bypass_options : Secret_scanning_delegated_bypass_options.t option;
        [@default None]
    secret_scanning_generic_secrets : Secret_scanning_generic_secrets.t option; [@default None]
    secret_scanning_non_provider_patterns : Secret_scanning_non_provider_patterns.t option;
        [@default None]
    secret_scanning_push_protection : Secret_scanning_push_protection.t option; [@default None]
    secret_scanning_validity_checks : Secret_scanning_validity_checks.t option; [@default None]
    target_type : Target_type.t option; [@default None]
    updated_at : string option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
