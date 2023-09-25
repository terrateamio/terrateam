module Primary = struct
  type t = {
    id : int;
    integration_url : string;
    node_id : string;
    slug : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
