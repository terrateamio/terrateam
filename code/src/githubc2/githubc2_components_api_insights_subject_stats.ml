module Items = struct
  module Primary = struct
    type t = {
      last_rate_limited_timestamp : string option; [@default None]
      last_request_timestamp : string option; [@default None]
      rate_limited_request_count : int option; [@default None]
      subject_id : int64 option; [@default None]
      subject_name : string option; [@default None]
      subject_type : string option; [@default None]
      total_request_count : int option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
