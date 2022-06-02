module Primary = struct
  module Config = struct
    module Primary = struct
      type t = {
        content_type : string option; [@default None]
        insecure_ssl : string option; [@default None]
        secret : string option; [@default None]
        url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Events = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    active : bool;
    config : Config.t;
    created_at : string;
    deliveries_url : string option; [@default None]
    events : Events.t;
    id : int;
    name : string;
    ping_url : string;
    type_ : string; [@key "type"]
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
