module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "published" -> Ok "published"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Registry_package = struct
    module Primary = struct
      module Owner = struct
        module Primary = struct
          type t = {
            avatar_url : string;
            events_url : string;
            followers_url : string;
            following_url : string;
            gists_url : string;
            gravatar_id : string;
            html_url : string;
            id : int;
            login : string;
            node_id : string;
            organizations_url : string;
            received_events_url : string;
            repos_url : string;
            site_admin : bool;
            starred_url : string;
            subscriptions_url : string;
            type_ : string; [@key "type"]
            url : string;
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
              type t = {
                avatar_url : string;
                events_url : string;
                followers_url : string;
                following_url : string;
                gists_url : string;
                gravatar_id : string;
                html_url : string;
                id : int;
                login : string;
                node_id : string;
                organizations_url : string;
                received_events_url : string;
                repos_url : string;
                site_admin : bool;
                starred_url : string;
                subscriptions_url : string;
                type_ : string; [@key "type"]
                url : string;
                user_view_type : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Body = struct
            module V0 = struct
              type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            module V1 = struct
              include
                Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
            end

            type t =
              | V0 of V0.t
              | V1 of V1.t
            [@@deriving show, eq]

            let of_yojson =
              Json_schema.one_of
                (let open CCResult in
                 [
                   (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                   (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                 ])

            let to_yojson = function
              | V0 v -> V0.to_yojson v
              | V1 v -> V1.to_yojson v
          end

          module Container_metadata = struct
            module Primary = struct
              module Labels = struct
                include
                  Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
              end

              module Manifest_ = struct
                include
                  Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
              end

              module Tag_ = struct
                module Primary = struct
                  type t = {
                    digest : string option; [@default None]
                    name : string option; [@default None]
                  }
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
              end

              type t = {
                labels : Labels.t option; [@default None]
                manifest : Manifest_.t option; [@default None]
                tag : Tag_.t option; [@default None]
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

          module Npm_metadata = struct
            module Primary = struct
              module Author = struct
                module V0 = struct
                  type t = string option
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                module V1 = struct
                  include
                    Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
                end

                type t =
                  | V0 of V0.t
                  | V1 of V1.t
                [@@deriving show, eq]

                let of_yojson =
                  Json_schema.one_of
                    (let open CCResult in
                     [
                       (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                       (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                     ])

                let to_yojson = function
                  | V0 v -> V0.to_yojson v
                  | V1 v -> V1.to_yojson v
              end

              module Bin = struct
                include
                  Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
              end

              module Bugs = struct
                module V0 = struct
                  type t = string option
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                module V1 = struct
                  include
                    Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
                end

                type t =
                  | V0 of V0.t
                  | V1 of V1.t
                [@@deriving show, eq]

                let of_yojson =
                  Json_schema.one_of
                    (let open CCResult in
                     [
                       (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                       (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                     ])

                let to_yojson = function
                  | V0 v -> V0.to_yojson v
                  | V1 v -> V1.to_yojson v
              end

              module Contributors = struct
                type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Cpu = struct
                type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Dependencies = struct
                include
                  Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
              end

              module Dev_dependencies = struct
                include
                  Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
              end

              module Directories = struct
                module V0 = struct
                  type t = string option
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                module V1 = struct
                  include
                    Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
                end

                type t =
                  | V0 of V0.t
                  | V1 of V1.t
                [@@deriving show, eq]

                let of_yojson =
                  Json_schema.one_of
                    (let open CCResult in
                     [
                       (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                       (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                     ])

                let to_yojson = function
                  | V0 v -> V0.to_yojson v
                  | V1 v -> V1.to_yojson v
              end

              module Dist = struct
                module V0 = struct
                  type t = string option
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                module V1 = struct
                  include
                    Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
                end

                type t =
                  | V0 of V0.t
                  | V1 of V1.t
                [@@deriving show, eq]

                let of_yojson =
                  Json_schema.one_of
                    (let open CCResult in
                     [
                       (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                       (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                     ])

                let to_yojson = function
                  | V0 v -> V0.to_yojson v
                  | V1 v -> V1.to_yojson v
              end

              module Engines = struct
                include
                  Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
              end

              module Files = struct
                type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Keywords = struct
                type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Maintainers = struct
                type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Man = struct
                include
                  Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
              end

              module Optional_dependencies = struct
                include
                  Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
              end

              module Os = struct
                type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Peer_dependencies = struct
                include
                  Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
              end

              module Repository_ = struct
                module V0 = struct
                  type t = string option
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                module V1 = struct
                  include
                    Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
                end

                type t =
                  | V0 of V0.t
                  | V1 of V1.t
                [@@deriving show, eq]

                let of_yojson =
                  Json_schema.one_of
                    (let open CCResult in
                     [
                       (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                       (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                     ])

                let to_yojson = function
                  | V0 v -> V0.to_yojson v
                  | V1 v -> V1.to_yojson v
              end

              module Scripts = struct
                include
                  Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
              end

              type t = {
                author : Author.t option; [@default None]
                bin : Bin.t option; [@default None]
                bugs : Bugs.t option; [@default None]
                commit_oid : string option; [@default None]
                contributors : Contributors.t option; [@default None]
                cpu : Cpu.t option; [@default None]
                deleted_by_id : int option; [@default None]
                dependencies : Dependencies.t option; [@default None]
                description : string option; [@default None]
                dev_dependencies : Dev_dependencies.t option; [@default None]
                directories : Directories.t option; [@default None]
                dist : Dist.t option; [@default None]
                engines : Engines.t option; [@default None]
                files : Files.t option; [@default None]
                git_head : string option; [@default None]
                has_shrinkwrap : bool option; [@default None]
                homepage : string option; [@default None]
                id : string option; [@default None]
                installation_command : string option; [@default None]
                keywords : Keywords.t option; [@default None]
                license : string option; [@default None]
                main : string option; [@default None]
                maintainers : Maintainers.t option; [@default None]
                man : Man.t option; [@default None]
                name : string option; [@default None]
                node_version : string option; [@default None]
                npm_user : string option; [@default None]
                npm_version : string option; [@default None]
                optional_dependencies : Optional_dependencies.t option; [@default None]
                os : Os.t option; [@default None]
                peer_dependencies : Peer_dependencies.t option; [@default None]
                published_via_actions : bool option; [@default None]
                readme : string option; [@default None]
                release_id : int option; [@default None]
                repository : Repository_.t option; [@default None]
                scripts : Scripts.t option; [@default None]
                version : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Nuget_metadata = struct
            module Items = struct
              module Primary = struct
                module Id = struct
                  module V0 = struct
                    type t = string option
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  module V1 = struct
                    include
                      Json_schema.Additional_properties.Make
                        (Json_schema.Empty_obj)
                        (Json_schema.Obj)
                  end

                  module V2 = struct
                    type t = int option
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  type t =
                    | V0 of V0.t
                    | V1 of V1.t
                    | V2 of V2.t
                  [@@deriving show, eq]

                  let of_yojson =
                    Json_schema.one_of
                      (let open CCResult in
                       [
                         (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                         (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                         (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
                       ])

                  let to_yojson = function
                    | V0 v -> V0.to_yojson v
                    | V1 v -> V1.to_yojson v
                    | V2 v -> V2.to_yojson v
                end

                module Value = struct
                  module V0 = struct
                    type t = bool [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  module V1 = struct
                    type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  module V2 = struct
                    type t = int [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  module V3 = struct
                    module Primary = struct
                      type t = {
                        branch : string option; [@default None]
                        commit : string option; [@default None]
                        type_ : string option; [@default None] [@key "type"]
                        url : string option; [@default None]
                      }
                      [@@deriving yojson { strict = false; meta = true }, show, eq]
                    end

                    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                  end

                  type t =
                    | V0 of V0.t
                    | V1 of V1.t
                    | V2 of V2.t
                    | V3 of V3.t
                  [@@deriving show, eq]

                  let of_yojson =
                    Json_schema.one_of
                      (let open CCResult in
                       [
                         (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                         (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                         (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
                         (fun v -> map (fun v -> V3 v) (V3.of_yojson v));
                       ])

                  let to_yojson = function
                    | V0 v -> V0.to_yojson v
                    | V1 v -> V1.to_yojson v
                    | V2 v -> V2.to_yojson v
                    | V3 v -> V3.to_yojson v
                end

                type t = {
                  id : Id.t option; [@default None]
                  name : string option; [@default None]
                  value : Value.t option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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
                  sha256 : string option; [@default None]
                  size : int;
                  state : string option; [@default None]
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
                    user_view_type : string option; [@default None]
                  }
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
              end

              type t = {
                author : Author.t option; [@default None]
                created_at : string option; [@default None]
                draft : bool option; [@default None]
                html_url : string option; [@default None]
                id : int option; [@default None]
                name : string option; [@default None]
                prerelease : bool option; [@default None]
                published_at : string option; [@default None]
                tag_name : string option; [@default None]
                target_commitish : string option; [@default None]
                url : string option; [@default None]
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
            body : Body.t option; [@default None]
            body_html : string option; [@default None]
            container_metadata : Container_metadata.t option; [@default None]
            created_at : string option; [@default None]
            description : string;
            docker_metadata : Docker_metadata.t option; [@default None]
            draft : bool option; [@default None]
            html_url : string;
            id : int;
            installation_command : string;
            manifest : string option; [@default None]
            metadata : Metadata_.t;
            name : string;
            npm_metadata : Npm_metadata.t option; [@default None]
            nuget_metadata : Nuget_metadata.t option; [@default None]
            package_files : Package_files.t;
            package_url : string;
            prerelease : bool option; [@default None]
            release : Release_.t option; [@default None]
            rubygems_metadata : Rubygems_metadata.t option; [@default None]
            summary : string;
            tag_name : string option; [@default None]
            target_commitish : string option; [@default None]
            target_oid : string option; [@default None]
            updated_at : string option; [@default None]
            version : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Registry = struct
        module Primary = struct
          type t = {
            about_url : string option; [@default None]
            name : string option; [@default None]
            type_ : string option; [@default None] [@key "type"]
            url : string option; [@default None]
            vendor : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        created_at : string option; [@default None]
        description : string option; [@default None]
        ecosystem : string;
        html_url : string;
        id : int;
        name : string;
        namespace : string;
        owner : Owner.t;
        package_type : string;
        package_version : Package_version_.t option; [@default None]
        registry : Registry.t option; [@default None]
        updated_at : string option; [@default None]
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
    registry_package : Registry_package.t;
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
