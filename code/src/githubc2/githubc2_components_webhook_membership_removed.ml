module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "removed" -> Ok "removed"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Member = struct
    module Primary = struct
      module Type = struct
        let t_of_yojson = function
          | `String "Bot" -> Ok "Bot"
          | `String "User" -> Ok "User"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        avatar_url : string option; [@default None]
        deleted : bool option; [@default None]
        email : string option; [@default None]
        events_url : string option; [@default None]
        followers_url : string option; [@default None]
        following_url : string option; [@default None]
        gists_url : string option; [@default None]
        gravatar_id : string option; [@default None]
        html_url : string option; [@default None]
        id : int;
        login : string;
        name : string option; [@default None]
        node_id : string option; [@default None]
        organizations_url : string option; [@default None]
        received_events_url : string option; [@default None]
        repos_url : string option; [@default None]
        site_admin : bool option; [@default None]
        starred_url : string option; [@default None]
        subscriptions_url : string option; [@default None]
        type_ : Type.t option; [@default None] [@key "type"]
        url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Scope = struct
    let t_of_yojson = function
      | `String "team" -> Ok "team"
      | `String "organization" -> Ok "organization"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Sender = struct
    module Primary = struct
      module Type = struct
        let t_of_yojson = function
          | `String "Bot" -> Ok "Bot"
          | `String "User" -> Ok "User"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        avatar_url : string option; [@default None]
        deleted : bool option; [@default None]
        email : string option; [@default None]
        events_url : string option; [@default None]
        followers_url : string option; [@default None]
        following_url : string option; [@default None]
        gists_url : string option; [@default None]
        gravatar_id : string option; [@default None]
        html_url : string option; [@default None]
        id : int;
        login : string;
        name : string option; [@default None]
        node_id : string option; [@default None]
        organizations_url : string option; [@default None]
        received_events_url : string option; [@default None]
        repos_url : string option; [@default None]
        site_admin : bool option; [@default None]
        starred_url : string option; [@default None]
        subscriptions_url : string option; [@default None]
        type_ : Type.t option; [@default None] [@key "type"]
        url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Team_ = struct
    module Primary = struct
      module Notification_setting = struct
        let t_of_yojson = function
          | `String "notifications_enabled" -> Ok "notifications_enabled"
          | `String "notifications_disabled" -> Ok "notifications_disabled"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Parent = struct
        module Primary = struct
          module Notification_setting = struct
            let t_of_yojson = function
              | `String "notifications_enabled" -> Ok "notifications_enabled"
              | `String "notifications_disabled" -> Ok "notifications_disabled"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Privacy = struct
            let t_of_yojson = function
              | `String "open" -> Ok "open"
              | `String "closed" -> Ok "closed"
              | `String "secret" -> Ok "secret"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            description : string option;
            html_url : string;
            id : int;
            members_url : string;
            name : string;
            node_id : string;
            notification_setting : Notification_setting.t;
            permission : string;
            privacy : Privacy.t;
            repositories_url : string;
            slug : string;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Privacy = struct
        let t_of_yojson = function
          | `String "open" -> Ok "open"
          | `String "closed" -> Ok "closed"
          | `String "secret" -> Ok "secret"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        deleted : bool option; [@default None]
        description : string option; [@default None]
        html_url : string option; [@default None]
        id : int;
        members_url : string option; [@default None]
        name : string;
        node_id : string option; [@default None]
        notification_setting : Notification_setting.t option; [@default None]
        parent : Parent.t option; [@default None]
        permission : string option; [@default None]
        privacy : Privacy.t option; [@default None]
        repositories_url : string option; [@default None]
        slug : string option; [@default None]
        url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    member : Member.t option;
    organization : Githubc2_components_organization_simple_webhooks.t;
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    scope : Scope.t;
    sender : Sender.t option;
    team : Team_.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
