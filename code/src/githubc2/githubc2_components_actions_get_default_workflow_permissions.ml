module Primary = struct
  type t = {
    can_approve_pull_request_reviews : bool;
    default_workflow_permissions : Githubc2_components_actions_default_workflow_permissions.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
