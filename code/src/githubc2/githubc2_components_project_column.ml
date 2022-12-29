module Primary = struct
  type t = {
    cards_url : string;
    created_at : string;
    id : int;
    name : string;
    node_id : string;
    project_url : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
