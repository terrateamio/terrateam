module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "edited" -> Ok "edited"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Changes = struct
    module Primary = struct
      module Admin_enforced = struct
        module Primary = struct
          type t = { from : bool option }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Authorized_actor_names = struct
        module Primary = struct
          module From = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { from : From.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Authorized_actors_only = struct
        module Primary = struct
          type t = { from : bool option }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Authorized_dismissal_actors_only = struct
        module Primary = struct
          type t = { from : bool option }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Linear_history_requirement_enforcement_level = struct
        module Primary = struct
          module From = struct
            let t_of_yojson = function
              | `String "off" -> Ok "off"
              | `String "non_admins" -> Ok "non_admins"
              | `String "everyone" -> Ok "everyone"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { from : From.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Lock_allows_fork_sync = struct
        module Primary = struct
          type t = { from : bool option }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Lock_branch_enforcement_level = struct
        module Primary = struct
          module From = struct
            let t_of_yojson = function
              | `String "off" -> Ok "off"
              | `String "non_admins" -> Ok "non_admins"
              | `String "everyone" -> Ok "everyone"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { from : From.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Pull_request_reviews_enforcement_level = struct
        module Primary = struct
          module From = struct
            let t_of_yojson = function
              | `String "off" -> Ok "off"
              | `String "non_admins" -> Ok "non_admins"
              | `String "everyone" -> Ok "everyone"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { from : From.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Require_last_push_approval = struct
        module Primary = struct
          type t = { from : bool option }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Required_status_checks = struct
        module Primary = struct
          module From = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { from : From.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Required_status_checks_enforcement_level = struct
        module Primary = struct
          module From = struct
            let t_of_yojson = function
              | `String "off" -> Ok "off"
              | `String "non_admins" -> Ok "non_admins"
              | `String "everyone" -> Ok "everyone"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { from : From.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        admin_enforced : Admin_enforced.t option; [@default None]
        authorized_actor_names : Authorized_actor_names.t option; [@default None]
        authorized_actors_only : Authorized_actors_only.t option; [@default None]
        authorized_dismissal_actors_only : Authorized_dismissal_actors_only.t option;
            [@default None]
        linear_history_requirement_enforcement_level :
          Linear_history_requirement_enforcement_level.t option;
            [@default None]
        lock_allows_fork_sync : Lock_allows_fork_sync.t option; [@default None]
        lock_branch_enforcement_level : Lock_branch_enforcement_level.t option; [@default None]
        pull_request_reviews_enforcement_level : Pull_request_reviews_enforcement_level.t option;
            [@default None]
        require_last_push_approval : Require_last_push_approval.t option; [@default None]
        required_status_checks : Required_status_checks.t option; [@default None]
        required_status_checks_enforcement_level : Required_status_checks_enforcement_level.t option;
            [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    changes : Changes.t option; [@default None]
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    rule : Githubc2_components_webhooks_rule.t;
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
