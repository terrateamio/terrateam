module Primary = struct
  module Allow_deletions = struct
    module Primary = struct
      type t = { enabled : bool option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Allow_force_pushes = struct
    module Primary = struct
      type t = { enabled : bool option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Allow_fork_syncing = struct
    module Primary = struct
      type t = { enabled : bool [@default false] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Block_creations = struct
    module Primary = struct
      type t = { enabled : bool option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Lock_branch = struct
    module Primary = struct
      type t = { enabled : bool [@default false] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Required_conversation_resolution = struct
    module Primary = struct
      type t = { enabled : bool option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Required_linear_history = struct
    module Primary = struct
      type t = { enabled : bool option [@default None] }
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
    enabled : bool option; [@default None]
    enforce_admins : Githubc2_components_protected_branch_admin_enforced.t option; [@default None]
    lock_branch : Lock_branch.t option; [@default None]
    name : string option; [@default None]
    protection_url : string option; [@default None]
    required_conversation_resolution : Required_conversation_resolution.t option; [@default None]
    required_linear_history : Required_linear_history.t option; [@default None]
    required_pull_request_reviews :
      Githubc2_components_protected_branch_pull_request_review.t option;
        [@default None]
    required_signatures : Required_signatures.t option; [@default None]
    required_status_checks : Githubc2_components_protected_branch_required_status_check.t option;
        [@default None]
    restrictions : Githubc2_components_branch_restriction_policy.t option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
