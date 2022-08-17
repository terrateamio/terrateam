module Primary = struct
  module Actor_location = struct
    module Primary = struct
      type t = { country_name : string option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Config = struct
    module Items = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Config_was = struct
    module Items = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Data = struct
    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
  end

  module Events = struct
    module Items = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Events_were = struct
    module Items = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    timestamp_ : int option; [@default None] [@key "@timestamp"]
    document_id_ : string option; [@default None] [@key "_document_id"]
    action : string option; [@default None]
    active : bool option; [@default None]
    active_was : bool option; [@default None]
    actor : string option; [@default None]
    actor_id : int option; [@default None]
    actor_location : Actor_location.t option; [@default None]
    blocked_user : string option; [@default None]
    business : string option; [@default None]
    config : Config.t option; [@default None]
    config_was : Config_was.t option; [@default None]
    content_type : string option; [@default None]
    created_at : int option; [@default None]
    data : Data.t option; [@default None]
    deploy_key_fingerprint : string option; [@default None]
    emoji : string option; [@default None]
    events : Events.t option; [@default None]
    events_were : Events_were.t option; [@default None]
    explanation : string option; [@default None]
    fingerprint : string option; [@default None]
    hook_id : int option; [@default None]
    limited_availability : bool option; [@default None]
    message : string option; [@default None]
    name : string option; [@default None]
    old_user : string option; [@default None]
    openssh_public_key : string option; [@default None]
    org : string option; [@default None]
    org_id : int option; [@default None]
    previous_visibility : string option; [@default None]
    read_only : bool option; [@default None]
    repo : string option; [@default None]
    repository : string option; [@default None]
    repository_public : bool option; [@default None]
    target_login : string option; [@default None]
    team : string option; [@default None]
    transport_protocol : int option; [@default None]
    transport_protocol_name : string option; [@default None]
    user : string option; [@default None]
    visibility : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
