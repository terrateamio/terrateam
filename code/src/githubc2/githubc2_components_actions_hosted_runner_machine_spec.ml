module Primary = struct
  type t = {
    cpu_cores : int;
    id : string;
    memory_gb : int;
    storage_gb : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
