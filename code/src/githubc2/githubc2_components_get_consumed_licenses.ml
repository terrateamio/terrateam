module Primary = struct
  module Users = struct
    module Items = struct
      module Primary = struct
        module Enterprise_server_emails = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        module Enterprise_server_user_ids = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        module Github_com_member_roles = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        module Github_com_orgs_with_pending_invites = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        module Github_com_verified_domain_emails = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          enterprise_server_emails : Enterprise_server_emails.t option; [@default None]
          enterprise_server_user : bool option; [@default None]
          enterprise_server_user_ids : Enterprise_server_user_ids.t option; [@default None]
          github_com_enterprise_role : string option; [@default None]
          github_com_login : string option; [@default None]
          github_com_member_roles : Github_com_member_roles.t option; [@default None]
          github_com_name : string option; [@default None]
          github_com_orgs_with_pending_invites : Github_com_orgs_with_pending_invites.t option;
              [@default None]
          github_com_profile : string option; [@default None]
          github_com_saml_name_id : string option; [@default None]
          github_com_user : bool option; [@default None]
          github_com_verified_domain_emails : Github_com_verified_domain_emails.t option;
              [@default None]
          license_type : string option; [@default None]
          total_user_accounts : int option; [@default None]
          visual_studio_subscription_email : string option; [@default None]
          visual_studio_subscription_user : bool option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    total_seats_consumed : int option; [@default None]
    total_seats_purchased : int option; [@default None]
    users : Users.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
