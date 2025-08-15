module Primary = struct
  module Alert_stats = struct
    type t = {
      closed_count : int;
      in_progress_count : int;
      open_count : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Managers = struct
    type t = Githubc2_components_simple_user.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Team_managers = struct
    type t = Githubc2_components_team.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    alert_stats : Alert_stats.t option; [@default None]
    closed_at : string option; [@default None]
    contact_link : string option; [@default None]
    created_at : string;
    description : string;
    ends_at : string;
    managers : Managers.t;
    name : string option; [@default None]
    number : int;
    published_at : string option; [@default None]
    state : Githubc2_components_campaign_state.t;
    team_managers : Team_managers.t option; [@default None]
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
