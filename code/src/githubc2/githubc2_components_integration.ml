module Primary = struct
  module Events = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Owner = struct
    type t =
      | Simple_user of Githubc2_components_simple_user.t
      | Enterprise of Githubc2_components_enterprise.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> Simple_user v) (Githubc2_components_simple_user.of_yojson v));
           (fun v -> map (fun v -> Enterprise v) (Githubc2_components_enterprise.of_yojson v));
         ])

    let to_yojson = function
      | Simple_user v -> Githubc2_components_simple_user.to_yojson v
      | Enterprise v -> Githubc2_components_enterprise.to_yojson v
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
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Additional = struct
      type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Additional)
  end

  type t = {
    client_id : string option; [@default None]
    client_secret : string option; [@default None]
    created_at : string;
    description : string option; [@default None]
    events : Events.t;
    external_url : string;
    html_url : string;
    id : int;
    installations_count : int option; [@default None]
    name : string;
    node_id : string;
    owner : Owner.t;
    pem : string option; [@default None]
    permissions : Permissions.t;
    slug : string option; [@default None]
    updated_at : string;
    webhook_secret : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
