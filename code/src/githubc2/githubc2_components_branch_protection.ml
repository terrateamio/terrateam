module Primary = struct
  module Allow_deletions = struct
    module Primary = struct
      type t = { enabled : bool option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Allow_force_pushes = struct
    module Primary = struct
      type t = { enabled : bool option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Required_conversation_resolution = struct
    module Primary = struct
      type t = { enabled : bool option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Required_linear_history = struct
    module Primary = struct
      type t = { enabled : bool option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Required_signatures = struct
    module Primary = struct
      type t = {
        enabled : bool;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Required_status_checks = struct
    module Primary = struct
      module Contexts = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        contexts : Contexts.t;
        contexts_url : string option; [@default None]
        enforcement_level : string option; [@default None]
        strict : bool option; [@default None]
        url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    allow_deletions : Allow_deletions.t option; [@default None]
    allow_force_pushes : Allow_force_pushes.t option; [@default None]
    enabled : bool option; [@default None]
    enforce_admins : Githubc2_components_protected_branch_admin_enforced.t option; [@default None]
    name : string option; [@default None]
    protection_url : string option; [@default None]
    required_conversation_resolution : Required_conversation_resolution.t option; [@default None]
    required_linear_history : Required_linear_history.t option; [@default None]
    required_pull_request_reviews :
      Githubc2_components_protected_branch_pull_request_review.t option;
        [@default None]
    required_signatures : Required_signatures.t option; [@default None]
    required_status_checks : Required_status_checks.t option; [@default None]
    restrictions : Githubc2_components_branch_restriction_policy.t option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
