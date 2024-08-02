module Primary = struct
  module Allow_deletions = struct
    type t = { enabled : bool } [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Allow_force_pushes = struct
    type t = { enabled : bool } [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Allow_fork_syncing = struct
    type t = { enabled : bool [@default false] }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Block_creations = struct
    type t = { enabled : bool } [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Enforce_admins = struct
    type t = {
      enabled : bool;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Lock_branch = struct
    type t = { enabled : bool [@default false] }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Required_conversation_resolution = struct
    type t = { enabled : bool option [@default None] }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Required_linear_history = struct
    type t = { enabled : bool } [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Required_pull_request_reviews = struct
    module Primary = struct
      module Bypass_pull_request_allowances = struct
        module Primary = struct
          module Apps = struct
            type t = Githubc2_components_integration.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Teams = struct
            type t = Githubc2_components_team.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Users = struct
            type t = Githubc2_components_simple_user.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            apps : Apps.t option; [@default None]
            teams : Teams.t;
            users : Users.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Dismissal_restrictions = struct
        module Primary = struct
          module Apps = struct
            type t = Githubc2_components_integration.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Teams = struct
            type t = Githubc2_components_team.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Users = struct
            type t = Githubc2_components_simple_user.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            apps : Apps.t option; [@default None]
            teams : Teams.t;
            teams_url : string;
            url : string;
            users : Users.t;
            users_url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        bypass_pull_request_allowances : Bypass_pull_request_allowances.t option; [@default None]
        dismiss_stale_reviews : bool option; [@default None]
        dismissal_restrictions : Dismissal_restrictions.t option; [@default None]
        require_code_owner_reviews : bool option; [@default None]
        require_last_push_approval : bool; [@default false]
        required_approving_review_count : int option; [@default None]
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Required_signatures = struct
    module Primary = struct
      type t = {
        enabled : bool;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    allow_deletions : Allow_deletions.t option; [@default None]
    allow_force_pushes : Allow_force_pushes.t option; [@default None]
    allow_fork_syncing : Allow_fork_syncing.t option; [@default None]
    block_creations : Block_creations.t option; [@default None]
    enforce_admins : Enforce_admins.t option; [@default None]
    lock_branch : Lock_branch.t option; [@default None]
    required_conversation_resolution : Required_conversation_resolution.t option; [@default None]
    required_linear_history : Required_linear_history.t option; [@default None]
    required_pull_request_reviews : Required_pull_request_reviews.t option; [@default None]
    required_signatures : Required_signatures.t option; [@default None]
    required_status_checks : Githubc2_components_status_check_policy.t option; [@default None]
    restrictions : Githubc2_components_branch_restriction_policy.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
