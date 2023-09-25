module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "edited" -> Ok "edited"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Changes = struct
    module Primary = struct
      module Body = struct
        module Primary = struct
          type t = { from : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = { body : Body.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Comment = struct
    module Primary = struct
      module Author_association_ = struct
        let t_of_yojson = function
          | `String "COLLABORATOR" -> Ok "COLLABORATOR"
          | `String "CONTRIBUTOR" -> Ok "CONTRIBUTOR"
          | `String "FIRST_TIMER" -> Ok "FIRST_TIMER"
          | `String "FIRST_TIME_CONTRIBUTOR" -> Ok "FIRST_TIME_CONTRIBUTOR"
          | `String "MANNEQUIN" -> Ok "MANNEQUIN"
          | `String "MEMBER" -> Ok "MEMBER"
          | `String "NONE" -> Ok "NONE"
          | `String "OWNER" -> Ok "OWNER"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Reactions = struct
        module Primary = struct
          type t = {
            plus_one : int; [@key "+1"]
            minus_one : int; [@key "-1"]
            confused : int;
            eyes : int;
            heart : int;
            hooray : int;
            laugh : int;
            rocket : int;
            total_count : int;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module User = struct
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

      type t = {
        author_association : Author_association_.t;
        body : string;
        child_comment_count : int;
        created_at : string;
        discussion_id : int;
        html_url : string;
        id : int;
        node_id : string;
        parent_id : int option;
        reactions : Reactions.t;
        repository_url : string;
        updated_at : string;
        user : User.t option;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    changes : Changes.t;
    comment : Comment.t;
    discussion : Githubc2_components_discussion.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user_webhooks.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
