module Primary = struct
  module Dismissal_restrictions = struct
    module Primary = struct
      module Teams = struct
        type t = Githubc2_components_team.t list
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Users = struct
        type t = Githubc2_components_simple_user.t list
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        teams : Teams.t option; [@default None]
        teams_url : string option; [@default None]
        url : string option; [@default None]
        users : Users.t option; [@default None]
        users_url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    dismiss_stale_reviews : bool;
    dismissal_restrictions : Dismissal_restrictions.t option; [@default None]
    require_code_owner_reviews : bool;
    required_approving_review_count : int option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
