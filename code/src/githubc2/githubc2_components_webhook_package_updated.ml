module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "updated" -> Ok "updated"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Package_ = struct
    module Primary = struct
      module Owner = struct
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

      module Package_version_ = struct
        module Primary = struct
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

          module Docker_metadata = struct
            module Items = struct
              module Primary = struct
                module Tags = struct
                  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                type t = { tags : Tags.t option [@default None] }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Metadata_ = struct
            module Items = struct
              include
                Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Package_files = struct
            module Items = struct
              module Primary = struct
                type t = {
                  content_type : string;
                  created_at : string;
                  download_url : string;
                  id : int;
                  md5 : string option; [@default None]
                  name : string;
                  sha1 : string option; [@default None]
                  sha256 : string;
                  size : int;
                  state : string;
                  updated_at : string;
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Release_ = struct
            module Primary = struct
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

              type t = {
                author : Author.t option; [@default None]
                created_at : string;
                draft : bool;
                html_url : string;
                id : int;
                name : string;
                prerelease : bool;
                published_at : string;
                tag_name : string;
                target_commitish : string;
                url : string;
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Rubygems_metadata = struct
            type t = Githubc2_components_webhook_rubygems_metadata.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            author : Author.t option; [@default None]
            body : string;
            body_html : string;
            created_at : string;
            description : string;
            docker_metadata : Docker_metadata.t option; [@default None]
            draft : bool option; [@default None]
            html_url : string;
            id : int;
            installation_command : string;
            manifest : string option; [@default None]
            metadata : Metadata_.t;
            name : string;
            package_files : Package_files.t;
            package_url : string option; [@default None]
            prerelease : bool option; [@default None]
            release : Release_.t option; [@default None]
            rubygems_metadata : Rubygems_metadata.t option; [@default None]
            source_url : string option; [@default None]
            summary : string;
            tag_name : string option; [@default None]
            target_commitish : string;
            target_oid : string;
            updated_at : string;
            version : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Registry = struct
        module Primary = struct
          type t = {
            about_url : string;
            name : string;
            type_ : string; [@key "type"]
            url : string;
            vendor : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        created_at : string;
        description : string option; [@default None]
        ecosystem : string;
        html_url : string;
        id : int;
        name : string;
        namespace : string;
        owner : Owner.t option; [@default None]
        package_type : string;
        package_version : Package_version_.t;
        registry : Registry.t option; [@default None]
        updated_at : string;
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
    package : Package_.t;
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
