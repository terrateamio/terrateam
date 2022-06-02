module Primary = struct
  type t = {
    body : string;
    id : int;
    node_id : string option; [@default None]
    title : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
