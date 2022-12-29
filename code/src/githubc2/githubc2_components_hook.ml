module Primary = struct
  module Config = struct
    module Primary = struct
      type t = {
        content_type : string option; [@default None]
        digest : string option; [@default None]
        email : string option; [@default None]
        insecure_ssl : Githubc2_components_webhook_config_insecure_ssl.t option; [@default None]
        password : string option; [@default None]
        room : string option; [@default None]
        secret : string option; [@default None]
        subdomain : string option; [@default None]
        token : string option; [@default None]
        url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Events = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    active : bool;
    config : Config.t;
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
