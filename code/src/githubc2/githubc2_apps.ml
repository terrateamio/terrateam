module Get_authenticated = struct
  module Parameters = struct end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Integration.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/app"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Create_from_manifest = struct
  module Parameters = struct
    type t = { code : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct
      module All_of = struct
        module Primary = struct
          module Events = struct
            type t = string list [@@deriving yojson { strict = false; meta = false }, show, eq]
          end

          module Permissions = struct
            module Primary = struct
              type t = {
                checks : string option; [@default None]
                contents : string option; [@default None]
                deployments : string option; [@default None]
                issues : string option; [@default None]
                metadata : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            module Additional = struct
              type t = string [@@deriving yojson { strict = false; meta = false }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Additional)
          end

          type t = {
            client_id : string;
            client_secret : string;
            created_at : string;
            description : string option;
            events : Events.t;
            external_url : string;
            html_url : string;
            id : int;
            installations_count : int option; [@default None]
            name : string;
            node_id : string;
            owner : Githubc2_components.Nullable_simple_user.t option;
            pem : string;
            permissions : Permissions.t;
            slug : string option; [@default None]
            updated_at : string;
            webhook_secret : string option;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module T = struct
        module Primary = struct
          module Events = struct
            type t = string list [@@deriving yojson { strict = false; meta = false }, show, eq]
          end

          module Permissions = struct
            module Primary = struct
              type t = {
                checks : string option; [@default None]
                contents : string option; [@default None]
                deployments : string option; [@default None]
                issues : string option; [@default None]
                metadata : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            module Additional = struct
              type t = string [@@deriving yojson { strict = false; meta = false }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Additional)
          end

          type t = {
            client_id : string;
            client_secret : string;
            created_at : string;
            description : string option;
            events : Events.t;
            external_url : string;
            html_url : string;
            id : int;
            installations_count : int option; [@default None]
            name : string;
            node_id : string;
            owner : Githubc2_components.Nullable_simple_user.t option;
            pem : string;
            permissions : Permissions.t;
            slug : string option; [@default None]
            updated_at : string;
            webhook_secret : string option;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = T.t [@@deriving yojson { strict = false; meta = false }, show, eq]

      let of_yojson json =
        let open CCResult in
        flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `Created of Created.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/app-manifests/{code}/conversions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("code", Var (params.code, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Update_webhook_config_for_app = struct
  module Parameters = struct end

  module Request_body = struct
    module Primary = struct
      type t = {
        content_type : string option; [@default None]
        insecure_ssl : Githubc2_components.Webhook_config_insecure_ssl.t option; [@default None]
        secret : string option; [@default None]
        url : string option; [@default None]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Webhook_config.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/app/hook/config"

  let make ~body () =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Get_webhook_config_for_app = struct
  module Parameters = struct end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Webhook_config.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/app/hook/config"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_webhook_deliveries = struct
  module Parameters = struct
    type t = {
      cursor : string option; [@default None]
      per_page : int; [@default 30]
      redelivery : bool option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Hook_delivery_item.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Bad_request of Bad_request.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/app/hook/deliveries"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("per_page", Var (params.per_page, Int));
           ("cursor", Var (params.cursor, Option String));
           ("redelivery", Var (params.redelivery, Option Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_webhook_delivery = struct
  module Parameters = struct
    type t = { delivery_id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Hook_delivery.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Bad_request of Bad_request.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/app/hook/deliveries/{delivery_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("delivery_id", Var (params.delivery_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Redeliver_webhook_delivery = struct
  module Parameters = struct
    type t = { delivery_id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Accepted = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `Accepted of Accepted.t
      | `Bad_request of Bad_request.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/app/hook/deliveries/{delivery_id}/attempts"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("delivery_id", Var (params.delivery_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_installation_requests_for_authenticated_app = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Integration_installation_request.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
      ]
  end

  let url = "/app/installation-requests"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_installations = struct
  module Parameters = struct
    type t = {
      outdated : string option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 30]
      since : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Items = struct
        module Primary = struct
          module Account = struct
            module All_of = struct
              module Primary = struct
                type t = {
                  avatar_url : string;
                  created_at : string option;
                  description : string option; [@default None]
                  email : string option; [@default None]
                  events_url : string;
                  followers_url : string;
                  following_url : string;
                  gists_url : string;
                  gravatar_id : string option;
                  html_url : string;
                  id : int;
                  login : string;
                  name : string option;
                  node_id : string;
                  organizations_url : string;
                  received_events_url : string;
                  repos_url : string;
                  site_admin : bool;
                  slug : string;
                  starred_at : string option; [@default None]
                  starred_url : string;
                  subscriptions_url : string;
                  type_ : string; [@key "type"]
                  updated_at : string option;
                  url : string;
                  website_url : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module T = struct
              module Primary = struct
                type t = {
                  avatar_url : string;
                  created_at : string option;
                  description : string option; [@default None]
                  email : string option; [@default None]
                  events_url : string;
                  followers_url : string;
                  following_url : string;
                  gists_url : string;
                  gravatar_id : string option;
                  html_url : string;
                  id : int;
                  login : string;
                  name : string option;
                  node_id : string;
                  organizations_url : string;
                  received_events_url : string;
                  repos_url : string;
                  site_admin : bool;
                  slug : string;
                  starred_at : string option; [@default None]
                  starred_url : string;
                  subscriptions_url : string;
                  type_ : string; [@key "type"]
                  updated_at : string option;
                  url : string;
                  website_url : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = T.t [@@deriving yojson { strict = false; meta = false }, show, eq]

            let of_yojson json =
              let open CCResult in
              flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
          end

          module Events = struct
            type t = string list [@@deriving yojson { strict = false; meta = false }, show, eq]
          end

          module Permissions = struct
            module Primary = struct
              module Actions = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Administration = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Checks = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Contents = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Deployments = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Environments = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Issues = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Members = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Metadata = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Organization_administration = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Organization_announcement_banners = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Organization_custom_roles = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Organization_hooks = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Organization_packages = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Organization_personal_access_token_requests = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Organization_personal_access_tokens = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Organization_plan = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Organization_projects = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | `String "admin" -> Ok "admin"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Organization_secrets = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Organization_self_hosted_runners = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Organization_user_blocking = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Packages = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Pages = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Pull_requests = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Repository_hooks = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Repository_projects = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | `String "admin" -> Ok "admin"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Secret_scanning_alerts = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Secrets = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Security_events = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Single_file = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Statuses = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Team_discussions = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Vulnerability_alerts = struct
                let t_of_yojson = function
                  | `String "read" -> Ok "read"
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              module Workflows = struct
                let t_of_yojson = function
                  | `String "write" -> Ok "write"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = false }, show, eq]
              end

              type t = {
                actions : Actions.t option; [@default None]
                administration : Administration.t option; [@default None]
                checks : Checks.t option; [@default None]
                contents : Contents.t option; [@default None]
                deployments : Deployments.t option; [@default None]
                environments : Environments.t option; [@default None]
                issues : Issues.t option; [@default None]
                members : Members.t option; [@default None]
                metadata : Metadata.t option; [@default None]
                organization_administration : Organization_administration.t option; [@default None]
                organization_announcement_banners : Organization_announcement_banners.t option;
                    [@default None]
                organization_custom_roles : Organization_custom_roles.t option; [@default None]
                organization_hooks : Organization_hooks.t option; [@default None]
                organization_packages : Organization_packages.t option; [@default None]
                organization_personal_access_token_requests :
                  Organization_personal_access_token_requests.t option;
                    [@default None]
                organization_personal_access_tokens : Organization_personal_access_tokens.t option;
                    [@default None]
                organization_plan : Organization_plan.t option; [@default None]
                organization_projects : Organization_projects.t option; [@default None]
                organization_secrets : Organization_secrets.t option; [@default None]
                organization_self_hosted_runners : Organization_self_hosted_runners.t option;
                    [@default None]
                organization_user_blocking : Organization_user_blocking.t option; [@default None]
                packages : Packages.t option; [@default None]
                pages : Pages.t option; [@default None]
                pull_requests : Pull_requests.t option; [@default None]
                repository_hooks : Repository_hooks.t option; [@default None]
                repository_projects : Repository_projects.t option; [@default None]
                secret_scanning_alerts : Secret_scanning_alerts.t option; [@default None]
                secrets : Secrets.t option; [@default None]
                security_events : Security_events.t option; [@default None]
                single_file : Single_file.t option; [@default None]
                statuses : Statuses.t option; [@default None]
                team_discussions : Team_discussions.t option; [@default None]
                vulnerability_alerts : Vulnerability_alerts.t option; [@default None]
                workflows : Workflows.t option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Repository_selection = struct
            let t_of_yojson = function
              | `String "all" -> Ok "all"
              | `String "selected" -> Ok "selected"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = false }, show, eq]
          end

          module Single_file_paths = struct
            type t = string list [@@deriving yojson { strict = false; meta = false }, show, eq]
          end

          module Suspended_by = struct
            module Primary = struct
              type t = {
                avatar_url : string;
                email : string option; [@default None]
                events_url : string;
                followers_url : string;
                following_url : string;
                gists_url : string;
                gravatar_id : string option;
                html_url : string;
                id : int;
                login : string;
                name : string option; [@default None]
                node_id : string;
                organizations_url : string;
                received_events_url : string;
                repos_url : string;
                site_admin : bool;
                starred_at : string option; [@default None]
                starred_url : string;
                subscriptions_url : string;
                type_ : string; [@key "type"]
                url : string;
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            access_tokens_url : string;
            account : Account.t option;
            app_id : int;
            app_slug : string;
            contact_email : string option; [@default None]
            created_at : string;
            events : Events.t;
            has_multiple_single_files : bool option; [@default None]
            html_url : string;
            id : int;
            permissions : Permissions.t;
            repositories_url : string;
            repository_selection : Repository_selection.t;
            single_file_name : string option;
            single_file_paths : Single_file_paths.t option; [@default None]
            suspended_at : string option;
            suspended_by : Suspended_by.t option;
            target_id : int;
            target_type : string;
            updated_at : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/app/installations"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("per_page", Var (params.per_page, Int));
           ("page", Var (params.page, Int));
           ("since", Var (params.since, Option String));
           ("outdated", Var (params.outdated, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_installation = struct
  module Parameters = struct
    type t = { installation_id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `No_content
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/app/installations/{installation_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("installation_id", Var (params.installation_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_installation = struct
  module Parameters = struct
    type t = { installation_id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Installation.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/app/installations/{installation_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("installation_id", Var (params.installation_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Create_installation_access_token = struct
  module Parameters = struct
    type t = { installation_id : int } [@@deriving make, show, eq]
  end

  module Request_body = struct
    module Primary = struct
      module Repositories = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Repository_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        permissions : Githubc2_components.App_permissions.t option; [@default None]
        repositories : Repositories.t option; [@default None]
        repository_ids : Repository_ids.t option; [@default None]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Installation_token.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `Created of Created.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/app/installations/{installation_id}/access_tokens"

  let make ?body params =
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("installation_id", Var (params.installation_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Unsuspend_installation = struct
  module Parameters = struct
    type t = { installation_id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `No_content
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/app/installations/{installation_id}/suspended"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("installation_id", Var (params.installation_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Suspend_installation = struct
  module Parameters = struct
    type t = { installation_id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `No_content
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/app/installations/{installation_id}/suspended"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("installation_id", Var (params.installation_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Delete_authorization = struct
  module Parameters = struct
    type t = { client_id : string } [@@deriving make, show, eq]
  end

  module Request_body = struct
    module Primary = struct
      type t = { access_token : string }
      [@@deriving make, yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `No_content
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/applications/{client_id}/grant"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("client_id", Var (params.client_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Reset_token = struct
  module Parameters = struct
    type t = { client_id : string } [@@deriving make, show, eq]
  end

  module Request_body = struct
    module Primary = struct
      type t = { access_token : string }
      [@@deriving make, yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Authorization.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/applications/{client_id}/token"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("client_id", Var (params.client_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete_token = struct
  module Parameters = struct
    type t = { client_id : string } [@@deriving make, show, eq]
  end

  module Request_body = struct
    module Primary = struct
      type t = { access_token : string }
      [@@deriving make, yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `No_content
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/applications/{client_id}/token"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("client_id", Var (params.client_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Check_token = struct
  module Parameters = struct
    type t = { client_id : string } [@@deriving make, show, eq]
  end

  module Request_body = struct
    module Primary = struct
      type t = { access_token : string }
      [@@deriving make, yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Authorization.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/applications/{client_id}/token"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("client_id", Var (params.client_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Scope_token = struct
  module Parameters = struct
    type t = { client_id : string } [@@deriving make, show, eq]
  end

  module Request_body = struct
    module Primary = struct
      module Repositories = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Repository_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        access_token : string;
        permissions : Githubc2_components.App_permissions.t option; [@default None]
        repositories : Repositories.t option; [@default None]
        repository_ids : Repository_ids.t option; [@default None]
        target : string option; [@default None]
        target_id : int option; [@default None]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Authorization.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/applications/{client_id}/token/scoped"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("client_id", Var (params.client_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Get_by_slug = struct
  module Parameters = struct
    type t = { app_slug : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Integration.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/apps/{app_slug}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("app_slug", Var (params.app_slug, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_repos_accessible_to_installation = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Repositories = struct
          type t = Githubc2_components.Repository.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          repositories : Repositories.t;
          repository_selection : string option; [@default None]
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
      ]
  end

  let url = "/installation/repositories"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Revoke_installation_access_token = struct
  module Parameters = struct end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/installation/token"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_subscription_plan_for_account = struct
  module Parameters = struct
    type t = { account_id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Marketplace_purchase.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/marketplace_listing/accounts/{account_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("account_id", Var (params.account_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_plans = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Marketplace_listing_plan.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/marketplace_listing/plans"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_accounts_for_plan = struct
  module Parameters = struct
    module Direction = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "updated" -> Ok "updated"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      direction : Direction.t option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 30]
      plan_id : int;
      sort : Sort.t; [@default "created"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Marketplace_purchase.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/marketplace_listing/plans/{plan_id}/accounts"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("plan_id", Var (params.plan_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("sort", Var (params.sort, String));
           ("direction", Var (params.direction, Option String));
           ("per_page", Var (params.per_page, Int));
           ("page", Var (params.page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_subscription_plan_for_account_stubbed = struct
  module Parameters = struct
    type t = { account_id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Marketplace_purchase.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct end

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/marketplace_listing/stubbed/accounts/{account_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("account_id", Var (params.account_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_plans_stubbed = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Marketplace_listing_plan.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
      ]
  end

  let url = "/marketplace_listing/stubbed/plans"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_accounts_for_plan_stubbed = struct
  module Parameters = struct
    module Direction = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "updated" -> Ok "updated"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      direction : Direction.t option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 30]
      plan_id : int;
      sort : Sort.t; [@default "created"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Marketplace_purchase.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
      ]
  end

  let url = "/marketplace_listing/stubbed/plans/{plan_id}/accounts"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("plan_id", Var (params.plan_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("sort", Var (params.sort, String));
           ("direction", Var (params.direction, Option String));
           ("per_page", Var (params.per_page, Int));
           ("page", Var (params.page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_org_installation = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Installation.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/installation"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("org", Var (params.org, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Get_repo_installation = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Installation.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Moved_permanently = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Moved_permanently of Moved_permanently.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("301", Openapi.of_json_body (fun v -> `Moved_permanently v) Moved_permanently.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/installation"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_installations_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Installations = struct
          type t = Githubc2_components.Installation.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          installations : Installations.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
      ]
  end

  let url = "/user/installations"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_installation_repos_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      installation_id : int;
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Repositories = struct
          type t = Githubc2_components.Repository.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          repositories : Repositories.t;
          repository_selection : string option; [@default None]
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/user/installations/{installation_id}/repositories"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("installation_id", Var (params.installation_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_repo_from_installation_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      installation_id : int;
      repository_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct end

    type t =
      [ `No_content
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/user/installations/{installation_id}/repositories/{repository_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("installation_id", Var (params.installation_id, Int));
           ("repository_id", Var (params.repository_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_repo_to_installation_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      installation_id : int;
      repository_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `No_content
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/user/installations/{installation_id}/repositories/{repository_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("installation_id", Var (params.installation_id, Int));
           ("repository_id", Var (params.repository_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_subscriptions_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.User_marketplace_purchase.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/user/marketplace_purchases"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_subscriptions_for_authenticated_user_stubbed = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.User_marketplace_purchase.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
      ]
  end

  let url = "/user/marketplace_purchases/stubbed"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_user_installation = struct
  module Parameters = struct
    type t = { username : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Installation.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/users/{username}/installation"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("username", Var (params.username, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
