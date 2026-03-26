module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "member_invited" -> Ok `Member_invited
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Member_invited -> `String "member_invited"

    type t = ([ `Member_invited ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Invitation = struct
    module Primary = struct
      module Inviter = struct
        module Primary = struct
          module Type = struct
            let t_of_yojson = function
              | `String "Bot" -> Ok `Bot
              | `String "Organization" -> Ok `Organization
              | `String "User" -> Ok `User
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            let t_to_yojson = function
              | `Bot -> `String "Bot"
              | `Organization -> `String "Organization"
              | `User -> `String "User"

            type t =
              ([ `Bot
               | `Organization
               | `User
               ]
              [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
            user_view_type : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        created_at : string;
        email : string option; [@default None]
        failed_at : string option; [@default None]
        failed_reason : string option; [@default None]
        id : float;
        invitation_source : string option; [@default None]
        invitation_teams_url : string;
        inviter : Inviter.t option; [@default None]
        login : string option; [@default None]
        node_id : string;
        role : string;
        team_count : float;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    invitation : Invitation.t;
    organization : Githubc2_components_organization_simple_webhooks.t;
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    sender : Githubc2_components_simple_user.t;
    user : Githubc2_components_webhooks_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
