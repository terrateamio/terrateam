module Primary = struct
  module Branches = struct
    module Items = struct
      module Primary = struct
        module Commit_ = struct
          module Primary = struct
            type t = {
              sha : string option; [@default None]
              url : string option; [@default None]
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
                  email : string option; [@default None]
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
                  email : string option; [@default None]
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
                  email : string option; [@default None]
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
                  email : string option; [@default None]
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
                  | `String "bad_cert" -> Ok `Bad_cert
                  | `String "bad_email" -> Ok `Bad_email
                  | `String "expired_key" -> Ok `Expired_key
                  | `String "gpgverify_error" -> Ok `Gpgverify_error
                  | `String "gpgverify_unavailable" -> Ok `Gpgverify_unavailable
                  | `String "invalid" -> Ok `Invalid
                  | `String "malformed_signature" -> Ok `Malformed_signature
                  | `String "no_user" -> Ok `No_user
                  | `String "not_signing_key" -> Ok `Not_signing_key
                  | `String "ocsp_pending" -> Ok `Ocsp_pending
                  | `String "unknown_key" -> Ok `Unknown_key
                  | `String "unknown_signature_type" -> Ok `Unknown_signature_type
                  | `String "unsigned" -> Ok `Unsigned
                  | `String "unverified_email" -> Ok `Unverified_email
                  | `String "valid" -> Ok `Valid
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                let t_to_yojson = function
                  | `Bad_cert -> `String "bad_cert"
                  | `Bad_email -> `String "bad_email"
                  | `Expired_key -> `String "expired_key"
                  | `Gpgverify_error -> `String "gpgverify_error"
                  | `Gpgverify_unavailable -> `String "gpgverify_unavailable"
                  | `Invalid -> `String "invalid"
                  | `Malformed_signature -> `String "malformed_signature"
                  | `No_user -> `String "no_user"
                  | `Not_signing_key -> `String "not_signing_key"
                  | `Ocsp_pending -> `String "ocsp_pending"
                  | `Unknown_key -> `String "unknown_key"
                  | `Unknown_signature_type -> `String "unknown_signature_type"
                  | `Unsigned -> `String "unsigned"
                  | `Unverified_email -> `String "unverified_email"
                  | `Valid -> `String "valid"

                type t =
                  ([ `Bad_cert
                   | `Bad_email
                   | `Expired_key
                   | `Gpgverify_error
                   | `Gpgverify_unavailable
                   | `Invalid
                   | `Malformed_signature
                   | `No_user
                   | `Not_signing_key
                   | `Ocsp_pending
                   | `Unknown_key
                   | `Unknown_signature_type
                   | `Unsigned
                   | `Unverified_email
                   | `Valid
                   ]
                  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              type t = {
                payload : string option; [@default None]
                reason : Reason.t;
                signature : string option; [@default None]
                verified : bool;
                verified_at : string option; [@default None]
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
        author : Author.t option; [@default None]
        comments_url : string;
        commit : Commit_.t;
        committer : Committer.t option; [@default None]
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
      | `String "error" -> Ok `Error
      | `String "failure" -> Ok `Failure
      | `String "pending" -> Ok `Pending
      | `String "success" -> Ok `Success
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Error -> `String "error"
      | `Failure -> `String "failure"
      | `Pending -> `String "pending"
      | `Success -> `String "success"

    type t =
      ([ `Error
       | `Failure
       | `Pending
       | `Success
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    avatar_url : string option; [@default None]
    branches : Branches.t;
    commit : Commit_.t;
    context : string;
    created_at : string;
    description : string option; [@default None]
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    id : int;
    installation : Githubc2_components_simple_installation.t option; [@default None]
    name : string;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t;
    sha : string;
    state : State.t;
    target_url : string option; [@default None]
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
