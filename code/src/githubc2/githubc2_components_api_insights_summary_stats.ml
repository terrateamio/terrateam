module Primary = struct
  type t = {
    rate_limited_request_count : int64 option; [@default None]
    total_request_count : int64 option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
