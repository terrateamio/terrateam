module Primary = struct
  type t = {
    active_caches_count : int;
    active_caches_size_in_bytes : int;
    full_name : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
