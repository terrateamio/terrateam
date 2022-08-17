module Primary = struct
  type t = {
    created_at : string option; [@default None]
    id : int option; [@default None]
    key : string;
    key_id : string;
    title : string option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
