module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "prereleased" -> Ok "prereleased"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Release_ = struct
    module Primary = struct
      module Assets = struct
        module Items = struct
          module Primary = struct
            module State = struct
              let t_of_yojson = function
                | `String "uploaded" -> Ok "uploaded"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            module Uploader = struct
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
              browser_download_url : string;
              content_type : string;
              created_at : string;
              download_count : int;
              id : int;
              label : string option; [@default None]
              name : string;
              node_id : string;
              size : int;
              state : State.t;
              updated_at : string;
              uploader : Uploader.t option; [@default None]
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Author = struct
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
            user_view_type : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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

      type t = {
        assets : Assets.t;
        assets_url : string;
        author : Author.t option; [@default None]
        body : string option; [@default None]
        created_at : string option; [@default None]
        discussion_url : string option; [@default None]
        draft : bool;
        html_url : string;
        id : int;
        name : string option; [@default None]
        node_id : string;
        prerelease : bool;
        published_at : string option; [@default None]
        reactions : Reactions.t option; [@default None]
        tag_name : string;
        tarball_url : string option; [@default None]
        target_commitish : string;
        upload_url : string;
        url : string;
        zipball_url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    release : Release_.t;
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
