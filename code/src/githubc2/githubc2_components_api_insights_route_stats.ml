module Items = struct
  module Primary = struct
    type t = {
      api_route : string option; [@default None]
      http_method : string option; [@default None]
      last_rate_limited_timestamp : string option; [@default None]
      last_request_timestamp : string option; [@default None]
      rate_limited_request_count : int64 option; [@default None]
      total_request_count : int64 option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
