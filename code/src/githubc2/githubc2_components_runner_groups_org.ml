module Primary = struct
  module Selected_workflows = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    allows_public_repositories : bool;
    default : bool;
    hosted_runners_url : string option; [@default None]
    id : float;
    inherited : bool;
    inherited_allows_public_repositories : bool option; [@default None]
    name : string;
    network_configuration_id : string option; [@default None]
    restricted_to_workflows : bool; [@default false]
    runners_url : string;
    selected_repositories_url : string option; [@default None]
    selected_workflows : Selected_workflows.t option; [@default None]
    visibility : string;
    workflow_restrictions_read_only : bool; [@default false]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
