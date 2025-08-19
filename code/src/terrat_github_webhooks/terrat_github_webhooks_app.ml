module Events = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Permissions = struct
  module Additional = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

type t = {
  created_at : string;
  description : string option; [@default None]
  events : Events.t option; [@default None]
  external_url : string;
  html_url : string;
  id : int;
  name : string;
  node_id : string;
  owner : Terrat_github_webhooks_user.t;
  permissions : Permissions.t option; [@default None]
  slug : string option; [@default None]
  updated_at : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
