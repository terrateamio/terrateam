module Primary = struct
  type t = {
    cluster_id : string option; [@default None]
    endpoint : string option; [@default None]
    gcp_project_id : string option; [@default None]
    machine_type : string option; [@default None]
    num_nodes : string option; [@default None]
    status_name : string option; [@default None]
    zone : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
