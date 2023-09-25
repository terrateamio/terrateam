module Primary = struct
  module Apps = struct
    module Items = struct
      module Primary = struct
        module Events = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Owner = struct
          module Primary = struct
            type t = {
              avatar_url : string option; [@default None]
              description : string option; [@default None]
              events_url : string option; [@default None]
              followers_url : string option; [@default None]
              following_url : string option; [@default None]
              gists_url : string option; [@default None]
              gravatar_id : string option; [@default None]
              hooks_url : string option; [@default None]
              html_url : string option; [@default None]
              id : int option; [@default None]
              issues_url : string option; [@default None]
              login : string option; [@default None]
              members_url : string option; [@default None]
              node_id : string option; [@default None]
              organizations_url : string option; [@default None]
              public_members_url : string option; [@default None]
              received_events_url : string option; [@default None]
              repos_url : string option; [@default None]
              site_admin : bool option; [@default None]
              starred_url : string option; [@default None]
              subscriptions_url : string option; [@default None]
              type_ : string option; [@default None] [@key "type"]
              url : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Permissions = struct
          module Primary = struct
            type t = {
              contents : string option; [@default None]
              issues : string option; [@default None]
              metadata : string option; [@default None]
              single_file : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          created_at : string option; [@default None]
          description : string option; [@default None]
          events : Events.t option; [@default None]
          external_url : string option; [@default None]
          html_url : string option; [@default None]
          id : int option; [@default None]
          name : string option; [@default None]
          node_id : string option; [@default None]
          owner : Owner.t option; [@default None]
          permissions : Permissions.t option; [@default None]
          slug : string option; [@default None]
          updated_at : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Teams = struct
    module Items = struct
      module Primary = struct
        type t = {
          description : string option; [@default None]
          html_url : string option; [@default None]
          id : int option; [@default None]
          members_url : string option; [@default None]
          name : string option; [@default None]
          node_id : string option; [@default None]
          notification_setting : string option; [@default None]
          parent : string option; [@default None]
          permission : string option; [@default None]
          privacy : string option; [@default None]
          repositories_url : string option; [@default None]
          slug : string option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Users = struct
    module Items = struct
      module Primary = struct
        type t = {
          avatar_url : string option; [@default None]
          events_url : string option; [@default None]
          followers_url : string option; [@default None]
          following_url : string option; [@default None]
          gists_url : string option; [@default None]
          gravatar_id : string option; [@default None]
          html_url : string option; [@default None]
          id : int option; [@default None]
          login : string option; [@default None]
          node_id : string option; [@default None]
          organizations_url : string option; [@default None]
          received_events_url : string option; [@default None]
          repos_url : string option; [@default None]
          site_admin : bool option; [@default None]
          starred_url : string option; [@default None]
          subscriptions_url : string option; [@default None]
          type_ : string option; [@default None] [@key "type"]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    apps : Apps.t;
    apps_url : string;
    teams : Teams.t;
    teams_url : string;
    url : string;
    users : Users.t;
    users_url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
