module Primary = struct
  type t = {
    app : Githubc2_components_custom_deployment_rule_app.t;
    enabled : bool;
    id : int;
    node_id : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
