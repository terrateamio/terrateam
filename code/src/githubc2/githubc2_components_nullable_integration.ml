module Primary = struct
  module Events = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Permissions = struct
    module Primary = struct
      type t = {
        checks : string option; [@default None]
        contents : string option; [@default None]
        deployments : string option; [@default None]
        issues : string option; [@default None]
        metadata : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Additional = struct
      type t = string [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Additional)
  end

  type t = {
    client_id : string option; [@default None]
    client_secret : string option; [@default None]
    created_at : string;
    description : string option;
    events : Events.t;
    external_url : string;
    html_url : string;
    id : int;
    installations_count : int option; [@default None]
    name : string;
    node_id : string;
    owner : Githubc2_components_nullable_simple_user.t option;
    pem : string option; [@default None]
    permissions : Permissions.t;
    slug : string option; [@default None]
    updated_at : string;
    webhook_secret : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
