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
        teams : Teams.t option; [@default None]
        users : Users.t option; [@default None]
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
        teams : Teams.t option; [@default None]
        teams_url : string option; [@default None]
        url : string option; [@default None]
        users : Users.t option; [@default None]
        users_url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    bypass_pull_request_allowances : Bypass_pull_request_allowances.t option; [@default None]
    dismiss_stale_reviews : bool;
    dismissal_restrictions : Dismissal_restrictions.t option; [@default None]
    require_code_owner_reviews : bool;
    required_approving_review_count : int option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
