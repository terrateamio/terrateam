module Primary = struct
  module Links_ = struct
    module Primary = struct
      module Current_user_organizations = struct
        type t = Githubc2_components_link_with_type.t list
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        current_user : Githubc2_components_link_with_type.t option; [@default None]
        current_user_actor : Githubc2_components_link_with_type.t option; [@default None]
        current_user_organization : Githubc2_components_link_with_type.t option; [@default None]
        current_user_organizations : Current_user_organizations.t option; [@default None]
        current_user_public : Githubc2_components_link_with_type.t option; [@default None]
        security_advisories : Githubc2_components_link_with_type.t option; [@default None]
        timeline : Githubc2_components_link_with_type.t;
        user : Githubc2_components_link_with_type.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Current_user_organization_urls = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    links_ : Links_.t; [@key "_links"]
    current_user_actor_url : string option; [@default None]
    current_user_organization_url : string option; [@default None]
    current_user_organization_urls : Current_user_organization_urls.t option; [@default None]
    current_user_public_url : string option; [@default None]
    current_user_url : string option; [@default None]
    security_advisories_url : string option; [@default None]
    timeline_url : string;
    user_url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
