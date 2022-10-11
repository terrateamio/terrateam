module Primary = struct
  type t = {
    created_at : string;
    id : int;
    key : string;
    title : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
