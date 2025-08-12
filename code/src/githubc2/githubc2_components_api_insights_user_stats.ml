module Items = struct
  module Primary = struct
    type t = {
      actor_id : int64 option; [@default None]
      actor_name : string option; [@default None]
      actor_type : string option; [@default None]
      integration_id : int64 option; [@default None]
      last_rate_limited_timestamp : string option; [@default None]
      last_request_timestamp : string option; [@default None]
      oauth_application_id : int64 option; [@default None]
      rate_limited_request_count : int option; [@default None]
      total_request_count : int option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
