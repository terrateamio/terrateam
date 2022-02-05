module Get_authenticated = struct
  module Parameters = struct end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Integration.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { code : string } [@@deriving make, show]
  end

  module Request_body = struct
    type t = Json_schema.Empty_obj.t [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Responses = struct
    module Created = struct
      module All_of = struct
        module Primary = struct
          module Events = struct
            type t = string list [@@deriving yojson { strict = false; meta = false }, show]
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
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            module Additional = struct
              type t = string [@@deriving yojson { strict = false; meta = false }, show]
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
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module T = struct
        module Primary = struct
          module Events = struct
            type t = string list [@@deriving yojson { strict = false; meta = false }, show]
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
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            module Additional = struct
              type t = string [@@deriving yojson { strict = false; meta = false }, show]
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
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = T.t [@@deriving yojson { strict = false; meta = false }, show]

      let of_yojson json =
        let open CCResult in
        flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/app-manifests/{code}/conversions"

  let make ?body params =
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
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Webhook_config.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/app/hook/config"

  let make ?body () =
    Openapi.Request.make
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
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Hook_delivery_item.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
        [ ("per_page", Var (params.per_page, Int)); ("cursor", Var (params.cursor, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_webhook_delivery = struct
  module Parameters = struct
    type t = { delivery_id : int } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Hook_delivery.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { delivery_id : int } [@@deriving make, show]
  end

  module Responses = struct
    module Accepted = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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

module List_installations = struct
  module Parameters = struct
    type t = {
      outdated : string option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 30]
      since : string option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Installation.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { installation_id : int } [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { installation_id : int } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Installation.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unsupported_media_type = struct
      module Primary = struct
        type t = {
          documentation_url : string;
          message : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "415",
          Openapi.of_json_body (fun v -> `Unsupported_media_type v) Unsupported_media_type.of_yojson
        );
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
    type t = { installation_id : int } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Repositories = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Repository_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        permissions : Githubc2_components.App_permissions.t option; [@default None]
        repositories : Repositories.t option; [@default None]
        repository_ids : Repository_ids.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Installation_token.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unsupported_media_type = struct
      module Primary = struct
        type t = {
          documentation_url : string;
          message : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "415",
          Openapi.of_json_body (fun v -> `Unsupported_media_type v) Unsupported_media_type.of_yojson
        );
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/app/installations/{installation_id}/access_tokens"

  let make ?body params =
    Openapi.Request.make
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
    type t = { installation_id : int } [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { installation_id : int } [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { client_id : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = { access_token : string } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { client_id : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = { access_token : string } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Authorization.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { client_id : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = { access_token : string } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { client_id : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = { access_token : string } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Authorization.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { client_id : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Repositories = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Repository_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        access_token : string;
        permissions : Githubc2_components.App_permissions.t option; [@default None]
        repositories : Repositories.t option; [@default None]
        repository_ids : Repository_ids.t option; [@default None]
        target : string option; [@default None]
        target_id : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Authorization.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { app_slug : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Integration.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unsupported_media_type = struct
      module Primary = struct
        type t = {
          documentation_url : string;
          message : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "415",
          Openapi.of_json_body (fun v -> `Unsupported_media_type v) Unsupported_media_type.of_yojson
        );
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

module Create_content_attachment = struct
  module Parameters = struct
    type t = { content_reference_id : int } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        body : string;
        title : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Content_reference_attachment.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Gone = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unsupported_media_type = struct
      module Primary = struct
        type t = {
          documentation_url : string;
          message : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("410", Openapi.of_json_body (fun v -> `Gone v) Gone.of_yojson);
        ( "415",
          Openapi.of_json_body (fun v -> `Unsupported_media_type v) Unsupported_media_type.of_yojson
        );
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/content_references/{content_reference_id}/attachments"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("content_reference_id", Var (params.content_reference_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_repos_accessible_to_installation = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Repositories = struct
          type t = Githubc2_components.Repository.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          repositories : Repositories.t;
          repository_selection : string option; [@default None]
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { account_id : int } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Marketplace_purchase.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Marketplace_listing_plan.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "updated" -> Ok "updated"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      direction : Direction.t option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 30]
      plan_id : int;
      sort : Sort.t; [@default "created"]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Marketplace_purchase.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { account_id : int } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Marketplace_purchase.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct end

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
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Marketplace_listing_plan.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "updated" -> Ok "updated"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      direction : Direction.t option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 30]
      plan_id : int;
      sort : Sort.t; [@default "created"]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Marketplace_purchase.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { org : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Installation.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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

module Create_content_attachment_for_repo = struct
  module Parameters = struct
    type t = {
      content_reference_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        body : string;
        title : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Content_reference_attachment.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Gone = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unsupported_media_type = struct
      module Primary = struct
        type t = {
          documentation_url : string;
          message : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("410", Openapi.of_json_body (fun v -> `Gone v) Gone.of_yojson);
        ( "415",
          Openapi.of_json_body (fun v -> `Unsupported_media_type v) Unsupported_media_type.of_yojson
        );
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/content_references/{content_reference_id}/attachments"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("content_reference_id", Var (params.content_reference_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Get_repo_installation = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Installation.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Moved_permanently = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Installations = struct
          type t = Githubc2_components.Installation.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          installations : Installations.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unsupported_media_type = struct
      module Primary = struct
        type t = {
          documentation_url : string;
          message : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ( "415",
          Openapi.of_json_body (fun v -> `Unsupported_media_type v) Unsupported_media_type.of_yojson
        );
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
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Repositories = struct
          type t = Githubc2_components.Repository.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          repositories : Repositories.t;
          repository_selection : string option; [@default None]
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
      `Delete
end

module Add_repo_to_installation_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      installation_id : int;
      repository_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.User_marketplace_purchase.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.User_marketplace_purchase.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
    type t = { username : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Installation.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
