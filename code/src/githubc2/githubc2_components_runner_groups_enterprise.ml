module Primary = struct
  module Selected_workflows = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    allows_public_repositories : bool;
    default : bool;
    id : float;
    name : string;
    restricted_to_workflows : bool; [@default false]
    runners_url : string;
    selected_organizations_url : string option; [@default None]
    selected_workflows : Selected_workflows.t option; [@default None]
    visibility : string;
    workflow_restrictions_read_only : bool; [@default false]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
