module Primary = struct
  type t = {
    action : string option; [@default None]
    delivered_at : string;
    duration : float;
    event : string;
    guid : string;
    id : int64;
    installation_id : int64 option; [@default None]
    redelivery : bool;
    repository_id : int64 option; [@default None]
    status : string;
    status_code : int;
    throttled_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
