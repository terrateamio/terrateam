module Primary = struct
  module Branches = struct
    module Items = struct
      module Primary = struct
        module Commit_ = struct
          module Primary = struct
            type t = {
              sha : string option;
              url : string option;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          commit : Commit_.t;
          name : string;
          protected : bool;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Commit_ = struct
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
            id : int option; [@default None]
            login : string option; [@default None]
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

      module Commit_ = struct
        module Primary = struct
          module Author = struct
            module All_of = struct
              module Primary = struct
                type t = {
                  date : string;
                  email : string option;
                  name : string;
                  username : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module T = struct
              module Primary = struct
                type t = {
                  date : string;
                  email : string option;
                  name : string;
                  username : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

            let of_yojson json =
              let open CCResult in
              flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
          end

          module Committer = struct
            module All_of = struct
              module Primary = struct
                type t = {
                  date : string;
                  email : string option;
                  name : string;
                  username : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module T = struct
              module Primary = struct
                type t = {
                  date : string;
                  email : string option;
                  name : string;
                  username : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

            let of_yojson json =
              let open CCResult in
              flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
          end

          module Tree = struct
            module Primary = struct
              type t = {
                sha : string;
                url : string;
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Verification_ = struct
            module Primary = struct
              module Reason = struct
                let t_of_yojson = function
                  | `String "expired_key" -> Ok "expired_key"
                  | `String "not_signing_key" -> Ok "not_signing_key"
                  | `String "gpgverify_error" -> Ok "gpgverify_error"
                  | `String "gpgverify_unavailable" -> Ok "gpgverify_unavailable"
                  | `String "unsigned" -> Ok "unsigned"
                  | `String "unknown_signature_type" -> Ok "unknown_signature_type"
                  | `String "no_user" -> Ok "no_user"
                  | `String "unverified_email" -> Ok "unverified_email"
                  | `String "bad_email" -> Ok "bad_email"
                  | `String "unknown_key" -> Ok "unknown_key"
                  | `String "malformed_signature" -> Ok "malformed_signature"
                  | `String "invalid" -> Ok "invalid"
                  | `String "valid" -> Ok "valid"
                  | `String "bad_cert" -> Ok "bad_cert"
                  | `String "ocsp_pending" -> Ok "ocsp_pending"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              type t = {
                payload : string option;
                reason : Reason.t;
                signature : string option;
                verified : bool;
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            author : Author.t;
            comment_count : int;
            committer : Committer.t;
            message : string;
            tree : Tree.t;
            url : string;
            verification : Verification_.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Committer = struct
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
            id : int option; [@default None]
            login : string option; [@default None]
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

      module Parents = struct
        module Items = struct
          module Primary = struct
            type t = {
              html_url : string;
              sha : string;
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        author : Author.t option;
        comments_url : string;
        commit : Commit_.t;
        committer : Committer.t option;
        html_url : string;
        node_id : string;
        parents : Parents.t;
        sha : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module State = struct
    let t_of_yojson = function
      | `String "pending" -> Ok "pending"
      | `String "success" -> Ok "success"
      | `String "failure" -> Ok "failure"
      | `String "error" -> Ok "error"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    avatar_url : string option; [@default None]
    branches : Branches.t;
    commit : Commit_.t;
    context : string;
    created_at : string;
    description : string option;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    id : int;
    installation : Githubc2_components_simple_installation.t option; [@default None]
    name : string;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user_webhooks.t;
    sha : string;
    state : State.t;
    target_url : string option;
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
