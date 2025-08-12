module Primary = struct
  module Events = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    active : bool;
    config : Githubc2_components_webhook_config.t;
    created_at : string;
    deliveries_url : string option; [@default None]
    events : Events.t;
    id : int;
    last_response : Githubc2_components_hook_response.t;
    name : string;
    ping_url : string;
    test_url : string;
    type_ : string; [@key "type"]
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
