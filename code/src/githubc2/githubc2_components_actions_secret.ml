module Primary = struct
  type t = {
    created_at : string;
    name : string;
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
