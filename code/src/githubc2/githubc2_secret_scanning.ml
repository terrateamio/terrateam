module List_alerts_for_org = struct
  module Parameters = struct
    module State = struct
      let t_of_yojson = function
        | `String "open" -> Ok "open"
        | `String "resolved" -> Ok "resolved"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      resolution : string option; [@default None]
      secret_type : string option; [@default None]
      state : State.t option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Organization_secret_scanning_alert.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Service_unavailable = struct
      module Primary = struct
        type t = {
          code : string option; [@default None]
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("503", Openapi.of_json_body (fun v -> `Service_unavailable v) Service_unavailable.of_yojson);
      ]
  end

  let url = "/orgs/{org}/secret-scanning/alerts"

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
          ("state", Var (params.state, Option String));
          ("secret_type", Var (params.secret_type, Option String));
          ("resolution", Var (params.resolution, Option String));
          ("page", Var (params.page, Int));
          ("per_page", Var (params.per_page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_alerts_for_repo = struct
  module Parameters = struct
    module State = struct
      let t_of_yojson = function
        | `String "open" -> Ok "open"
        | `String "resolved" -> Ok "resolved"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
      resolution : string option; [@default None]
      secret_type : string option; [@default None]
      state : State.t option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Secret_scanning_alert.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct end

    module Service_unavailable = struct
      module Primary = struct
        type t = {
          code : string option; [@default None]
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", fun _ -> Ok `Not_found);
        ("503", Openapi.of_json_body (fun v -> `Service_unavailable v) Service_unavailable.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/secret-scanning/alerts"

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
          ("state", Var (params.state, Option String));
          ("secret_type", Var (params.secret_type, Option String));
          ("resolution", Var (params.resolution, Option String));
          ("page", Var (params.page, Int));
          ("per_page", Var (params.per_page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update_alert = struct
  module Parameters = struct
    type t = {
      alert_number : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        resolution : Githubc2_components.Secret_scanning_alert_resolution.t option; [@default None]
        state : Githubc2_components.Secret_scanning_alert_state.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Secret_scanning_alert.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct end
    module Unprocessable_entity = struct end

    module Service_unavailable = struct
      module Primary = struct
        type t = {
          code : string option; [@default None]
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
        ("503", Openapi.of_json_body (fun v -> `Service_unavailable v) Service_unavailable.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/secret-scanning/alerts/{alert_number}"

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
          ("alert_number", Var (params.alert_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Get_alert = struct
  module Parameters = struct
    type t = {
      alert_number : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Secret_scanning_alert.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end
    module Not_found = struct end

    module Service_unavailable = struct
      module Primary = struct
        type t = {
          code : string option; [@default None]
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("404", fun _ -> Ok `Not_found);
        ("503", Openapi.of_json_body (fun v -> `Service_unavailable v) Service_unavailable.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/secret-scanning/alerts/{alert_number}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("alert_number", Var (params.alert_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
