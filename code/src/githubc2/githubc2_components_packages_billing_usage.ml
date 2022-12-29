module Primary = struct
  type t = {
    included_gigabytes_bandwidth : int;
    total_gigabytes_bandwidth_used : int;
    total_paid_gigabytes_bandwidth_used : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
