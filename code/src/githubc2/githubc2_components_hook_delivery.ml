module Primary = struct
  module Request = struct
    module Primary = struct
      module Headers = struct
        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
      end

      module Payload = struct
        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
      end

      type t = {
        headers : Headers.t option; [@default None]
        payload : Payload.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Response = struct
    module Primary = struct
      module Headers = struct
        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
      end

      type t = {
        headers : Headers.t option; [@default None]
        payload : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : string option; [@default None]
    delivered_at : string;
    duration : float;
    event : string;
    guid : string;
    id : int;
    installation_id : int option; [@default None]
    redelivery : bool;
    repository_id : int option; [@default None]
    request : Request.t;
    response : Response.t;
    status : string;
    status_code : int;
    throttled_at : string option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
