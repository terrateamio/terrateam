module List_in_organization = struct
  module Parameters = struct
    type t = {
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Codespaces = struct
          type t = Githubc2_components.Codespace.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          codespaces : Codespaces.t;
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

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/orgs/{org}/codespaces"

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
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_from_organization = struct
  module Parameters = struct
    type t = {
      codespace_name : string;
      org : string;
      username : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Accepted = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
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

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `Accepted of Accepted.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/orgs/{org}/members/{username}/codespaces/{codespace_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String));
          ("username", Var (params.username, String));
          ("codespace_name", Var (params.codespace_name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Stop_in_organization = struct
  module Parameters = struct
    type t = {
      codespace_name : string;
      org : string;
      username : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Codespace.t
      [@@deriving yojson { strict = false; meta = false }, show]
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

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/orgs/{org}/members/{username}/codespaces/{codespace_name}/stop"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String));
          ("username", Var (params.username, String));
          ("codespace_name", Var (params.codespace_name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Create_with_repo_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        client_ip : string option; [@default None]
        devcontainer_path : string option; [@default None]
        display_name : string option; [@default None]
        idle_timeout_minutes : int option; [@default None]
        location : string option; [@default None]
        machine : string option; [@default None]
        multi_repo_permissions_opt_out : bool option; [@default None]
        ref_ : string option; [@default None] [@key "ref"]
        retention_period_minutes : int option; [@default None]
        working_directory : string option; [@default None]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Codespace.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Accepted = struct
      type t = Githubc2_components.Codespace.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
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

    type t =
      [ `Created of Created.t
      | `Accepted of Accepted.t
      | `Bad_request of Bad_request.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/codespaces"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_in_repository_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Codespaces = struct
          type t = Githubc2_components.Codespace.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          codespaces : Codespaces.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/repos/{owner}/{repo}/codespaces"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_devcontainers_in_repository_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Devcontainers = struct
          module Items = struct
            module Primary = struct
              type t = {
                name : string option; [@default None]
                path : string;
              }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          devcontainers : Devcontainers.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
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

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Bad_request of Bad_request.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/repos/{owner}/{repo}/codespaces/devcontainers"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Repo_machines_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      client_ip : string option; [@default None]
      location : string option; [@default None]
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Machines = struct
          type t = Githubc2_components.Codespace_machine.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          machines : Machines.t;
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

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/repos/{owner}/{repo}/codespaces/machines"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("location", Var (params.location, Option String));
          ("client_ip", Var (params.client_ip, Option String));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Pre_flight_with_repo_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      client_ip : string option; [@default None]
      owner : string;
      ref_ : string option; [@default None] [@key "ref"]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Defaults = struct
          module Primary = struct
            type t = {
              devcontainer_path : string option;
              location : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          billable_owner : Githubc2_components.Simple_user.t option; [@default None]
          defaults : Defaults.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/codespaces/new"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("ref", Var (params.ref_, Option String));
          ("client_ip", Var (params.client_ip, Option String));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_repo_secrets = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Secrets = struct
          type t = Githubc2_components.Repo_codespaces_secret.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          secrets : Secrets.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/codespaces/secrets"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_repo_public_key = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Codespaces_public_key.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/codespaces/secrets/public-key"

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

module Delete_repo_secret = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      secret_name : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/codespaces/secrets/{secret_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("secret_name", Var (params.secret_name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_or_update_repo_secret = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      secret_name : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        encrypted_value : string option; [@default None]
        key_id : string option; [@default None]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Json_schema.Empty_obj.t [@@deriving yojson { strict = false; meta = false }, show]
    end

    module No_content = struct end

    type t =
      [ `Created of Created.t
      | `No_content
      ]
    [@@deriving show]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("204", fun _ -> Ok `No_content);
      ]
  end

  let url = "/repos/{owner}/{repo}/codespaces/secrets/{secret_name}"

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
          ("secret_name", Var (params.secret_name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_repo_secret = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      secret_name : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Repo_codespaces_secret.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/codespaces/secrets/{secret_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("secret_name", Var (params.secret_name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Create_with_pr_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        client_ip : string option; [@default None]
        devcontainer_path : string option; [@default None]
        display_name : string option; [@default None]
        idle_timeout_minutes : int option; [@default None]
        location : string option; [@default None]
        machine : string option; [@default None]
        multi_repo_permissions_opt_out : bool option; [@default None]
        retention_period_minutes : int option; [@default None]
        working_directory : string option; [@default None]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Codespace.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Accepted = struct
      type t = Githubc2_components.Codespace.t
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

    type t =
      [ `Created of Created.t
      | `Accepted of Accepted.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/codespaces"

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
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Create_for_authenticated_user = struct
  module Parameters = struct end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        type t = {
          client_ip : string option; [@default None]
          devcontainer_path : string option; [@default None]
          display_name : string option; [@default None]
          idle_timeout_minutes : int option; [@default None]
          location : string option; [@default None]
          machine : string option; [@default None]
          multi_repo_permissions_opt_out : bool option; [@default None]
          ref_ : string option; [@default None] [@key "ref"]
          repository_id : int;
          retention_period_minutes : int option; [@default None]
          working_directory : string option; [@default None]
        }
        [@@deriving make, yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module V1 = struct
      module Primary = struct
        module Pull_request = struct
          module Primary = struct
            type t = {
              pull_request_number : int;
              repository_id : int;
            }
            [@@deriving make, yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          devcontainer_path : string option; [@default None]
          idle_timeout_minutes : int option; [@default None]
          location : string option; [@default None]
          machine : string option; [@default None]
          pull_request : Pull_request.t;
          working_directory : string option; [@default None]
        }
        [@@deriving make, yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t =
      | V0 of V0.t
      | V1 of V1.t
    [@@deriving show]

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

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Codespace.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Accepted = struct
      type t = Githubc2_components.Codespace.t
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

    type t =
      [ `Created of Created.t
      | `Accepted of Accepted.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/user/codespaces"

  let make ~body () =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
      repository_id : int option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Codespaces = struct
          type t = Githubc2_components.Codespace.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          codespaces : Codespaces.t;
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

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/user/codespaces"

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
          ("repository_id", Var (params.repository_id, Option Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_secrets_for_authenticated_user = struct
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
        module Secrets = struct
          type t = Githubc2_components.Codespaces_secret.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          secrets : Secrets.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/user/codespaces/secrets"

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

module Get_public_key_for_authenticated_user = struct
  module Parameters = struct end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Codespaces_user_public_key.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/user/codespaces/secrets/public-key"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_secret_for_authenticated_user = struct
  module Parameters = struct
    type t = { secret_name : string } [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/user/codespaces/secrets/{secret_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("secret_name", Var (params.secret_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_or_update_secret_for_authenticated_user = struct
  module Parameters = struct
    type t = { secret_name : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Selected_repository_ids = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        encrypted_value : string option; [@default None]
        key_id : string;
        selected_repository_ids : Selected_repository_ids.t option; [@default None]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Json_schema.Empty_obj.t [@@deriving yojson { strict = false; meta = false }, show]
    end

    module No_content = struct end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `Created of Created.t
      | `No_content
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("204", fun _ -> Ok `No_content);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/user/codespaces/secrets/{secret_name}"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("secret_name", Var (params.secret_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_secret_for_authenticated_user = struct
  module Parameters = struct
    type t = { secret_name : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Codespaces_secret.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/user/codespaces/secrets/{secret_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("secret_name", Var (params.secret_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Set_repositories_for_secret_for_authenticated_user = struct
  module Parameters = struct
    type t = { secret_name : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Selected_repository_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { selected_repository_ids : Selected_repository_ids.t }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

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

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/user/codespaces/secrets/{secret_name}/repositories"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("secret_name", Var (params.secret_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_repositories_for_secret_for_authenticated_user = struct
  module Parameters = struct
    type t = { secret_name : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Repositories = struct
          type t = Githubc2_components.Minimal_repository.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          repositories : Repositories.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/user/codespaces/secrets/{secret_name}/repositories"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("secret_name", Var (params.secret_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_repository_for_secret_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      repository_id : int;
      secret_name : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

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

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/user/codespaces/secrets/{secret_name}/repositories/{repository_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("secret_name", Var (params.secret_name, String));
          ("repository_id", Var (params.repository_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_repository_for_secret_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      repository_id : int;
      secret_name : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

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

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/user/codespaces/secrets/{secret_name}/repositories/{repository_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("secret_name", Var (params.secret_name, String));
          ("repository_id", Var (params.repository_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Update_for_authenticated_user = struct
  module Parameters = struct
    type t = { codespace_name : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Recent_folders = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        display_name : string option; [@default None]
        machine : string option; [@default None]
        recent_folders : Recent_folders.t option; [@default None]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Codespace.t
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

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/user/codespaces/{codespace_name}"

  let make ?body params =
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("codespace_name", Var (params.codespace_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete_for_authenticated_user = struct
  module Parameters = struct
    type t = { codespace_name : string } [@@deriving make, show]
  end

  module Responses = struct
    module Accepted = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
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

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `Accepted of Accepted.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/user/codespaces/{codespace_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("codespace_name", Var (params.codespace_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_for_authenticated_user = struct
  module Parameters = struct
    type t = { codespace_name : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Codespace.t
      [@@deriving yojson { strict = false; meta = false }, show]
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

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/user/codespaces/{codespace_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("codespace_name", Var (params.codespace_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Export_for_authenticated_user = struct
  module Parameters = struct
    type t = { codespace_name : string } [@@deriving make, show]
  end

  module Responses = struct
    module Accepted = struct
      type t = Githubc2_components.Codespace_export_details.t
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

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `Accepted of Accepted.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/user/codespaces/{codespace_name}/exports"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("codespace_name", Var (params.codespace_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Get_export_details_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      codespace_name : string;
      export_id : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Codespace_export_details.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/user/codespaces/{codespace_name}/exports/{export_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("codespace_name", Var (params.codespace_name, String));
          ("export_id", Var (params.export_id, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Codespace_machines_for_authenticated_user = struct
  module Parameters = struct
    type t = { codespace_name : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Machines = struct
          type t = Githubc2_components.Codespace_machine.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          machines : Machines.t;
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

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/user/codespaces/{codespace_name}/machines"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("codespace_name", Var (params.codespace_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Start_for_authenticated_user = struct
  module Parameters = struct
    type t = { codespace_name : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Codespace.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Payment_required = struct
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

    module Conflict = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Bad_request of Bad_request.t
      | `Unauthorized of Unauthorized.t
      | `Payment_required of Payment_required.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Conflict of Conflict.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("402", Openapi.of_json_body (fun v -> `Payment_required v) Payment_required.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("409", Openapi.of_json_body (fun v -> `Conflict v) Conflict.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/user/codespaces/{codespace_name}/start"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("codespace_name", Var (params.codespace_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Stop_for_authenticated_user = struct
  module Parameters = struct
    type t = { codespace_name : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Codespace.t
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

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Internal_server_error of Internal_server_error.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/user/codespaces/{codespace_name}/stop"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("codespace_name", Var (params.codespace_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end