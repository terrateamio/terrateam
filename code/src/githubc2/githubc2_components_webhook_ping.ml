module Primary = struct
  module Hook_ = struct
    module Primary = struct
      module Config = struct
        module Primary = struct
          type t = {
            content_type : string option; [@default None]
            insecure_ssl : Githubc2_components_webhook_config_insecure_ssl.t option; [@default None]
            secret : string option; [@default None]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Events = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Name = struct
        let t_of_yojson = function
          | `String "web" -> Ok "web"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        active : bool;
        app_id : int option; [@default None]
        config : Config.t;
        created_at : string;
        deliveries_url : string option; [@default None]
        events : Events.t;
        id : int;
        last_response : Githubc2_components_hook_response.t option; [@default None]
        name : Name.t;
        ping_url : string option; [@default None]
        test_url : string option; [@default None]
        type_ : string; [@key "type"]
        updated_at : string;
        url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    hook : Hook_.t option; [@default None]
    hook_id : int option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    sender : Githubc2_components_simple_user_webhooks.t option; [@default None]
    zen : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
