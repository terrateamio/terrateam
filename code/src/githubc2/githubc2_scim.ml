module Provision_and_invite_user = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Emails = struct
        module Items = struct
          module Primary = struct
            type t = {
              primary : bool option; [@default None]
              type_ : string option; [@default None] [@key "type"]
              value : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Groups = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Name = struct
        module Primary = struct
          type t = {
            familyname : string; [@key "familyName"]
            formatted : string option; [@default None]
            givenname : string; [@key "givenName"]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Schemas = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        active : bool option; [@default None]
        displayname : string option; [@default None] [@key "displayName"]
        emails : Emails.t;
        externalid : string option; [@default None] [@key "externalId"]
        groups : Groups.t option; [@default None]
        name : Name.t;
        schemas : Schemas.t option; [@default None]
        username : string; [@key "userName"]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct end
    module Not_modified = struct end

    module Bad_request = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Conflict = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Internal_server_error = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("304", fun _ -> Ok `Not_modified);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("409", Openapi.of_json_body (fun v -> `Conflict v) Conflict.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/scim/v2/organizations/{org}/Users"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_provisioned_identities = struct
  module Parameters = struct
    type t = {
      count : int option; [@default None]
      filter : string option; [@default None]
      org : string;
      startindex : int option; [@default None] [@key "startIndex"]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct end
    module Not_modified = struct end

    module Bad_request = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("304", fun _ -> Ok `Not_modified);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/scim/v2/organizations/{org}/Users"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("startIndex", Var (params.startindex, Option Int));
          ("count", Var (params.count, Option Int));
          ("filter", Var (params.filter, Option String));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update_attribute_for_user = struct
  module Parameters = struct
    type t = {
      org : string;
      scim_user_id : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Operations = struct
        module Items = struct
          module Primary = struct
            module Op = struct
              let t_of_yojson = function
                | `String "add" -> Ok "add"
                | `String "remove" -> Ok "remove"
                | `String "replace" -> Ok "replace"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            module Value = struct
              module V0 = struct
                module Primary = struct
                  type t = {
                    active : bool option; [@default None]
                    externalid : string option; [@default None] [@key "externalId"]
                    familyname : string option; [@default None] [@key "familyName"]
                    givenname : string option; [@default None] [@key "givenName"]
                    username : string option; [@default None] [@key "userName"]
                  }
                  [@@deriving yojson { strict = false; meta = true }, show]
                end

                include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
              end

              module V1 = struct
                module Items = struct
                  module Primary = struct
                    type t = {
                      primary : bool option; [@default None]
                      value : string option; [@default None]
                    }
                    [@@deriving yojson { strict = false; meta = true }, show]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
              end

              module V2 = struct
                type t = string [@@deriving yojson { strict = false; meta = true }, show]
              end

              type t =
                | V0 of V0.t
                | V1 of V1.t
                | V2 of V2.t
              [@@deriving show]

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

            type t = {
              op : Op.t;
              path : string option; [@default None]
              value : Value.t option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Schemas = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        operations : Operations.t; [@key "Operations"]
        schemas : Schemas.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct end
    module Not_modified = struct end

    module Bad_request = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Too_many_requests = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("304", fun _ -> Ok `Not_modified);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("429", Openapi.of_json_body (fun v -> `Too_many_requests v) Too_many_requests.of_yojson);
      ]
  end

  let url = "/scim/v2/organizations/{org}/Users/{scim_user_id}"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)); ("scim_user_id", Var (params.scim_user_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete_user_from_org = struct
  module Parameters = struct
    type t = {
      org : string;
      scim_user_id : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Scim_error.t
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

  let url = "/scim/v2/organizations/{org}/Users/{scim_user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)); ("scim_user_id", Var (params.scim_user_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Set_information_for_provisioned_user = struct
  module Parameters = struct
    type t = {
      org : string;
      scim_user_id : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Emails = struct
        module Items = struct
          module Primary = struct
            type t = {
              primary : bool option; [@default None]
              type_ : string option; [@default None] [@key "type"]
              value : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Groups = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Name = struct
        module Primary = struct
          type t = {
            familyname : string; [@key "familyName"]
            formatted : string option; [@default None]
            givenname : string; [@key "givenName"]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Schemas = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        active : bool option; [@default None]
        displayname : string option; [@default None] [@key "displayName"]
        emails : Emails.t;
        externalid : string option; [@default None] [@key "externalId"]
        groups : Groups.t option; [@default None]
        name : Name.t;
        schemas : Schemas.t option; [@default None]
        username : string; [@key "userName"]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/scim/v2/organizations/{org}/Users/{scim_user_id}"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)); ("scim_user_id", Var (params.scim_user_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_provisioning_information_for_user = struct
  module Parameters = struct
    type t = {
      org : string;
      scim_user_id : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Scim_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/scim/v2/organizations/{org}/Users/{scim_user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)); ("scim_user_id", Var (params.scim_user_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
