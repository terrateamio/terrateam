module Primary = struct
  type t = {
    total_active_caches_count : int;
    total_active_caches_size_in_bytes : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
