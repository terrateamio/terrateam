module List_dirspaces = struct
  module Parameters = struct
    module D = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Page = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      d : D.t option; [@default None]
      installation_id : string;
      limit : int option; [@default None]
      page : Page.t option; [@default None]
      q : string option; [@default None]
      tz : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Dirspaces = struct
        type t = Terrat_api_components.Installation_dirspace.t list
        [@@deriving yojson { strict = false; meta = false }, show, eq]
      end

      type t = { dirspaces : Dirspaces.t }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Bad_request = struct
      type t = Terrat_api_components.Bad_request_err.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct end

    type t =
      [ `OK of OK.t
      | `Bad_request of Bad_request.t
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v1/github/installations/{installation_id}/dirspaces"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("installation_id", Var (params.installation_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Option (Array String)));
           ("q", Var (params.q, Option String));
           ("d", Var (params.d, Option String));
           ("tz", Var (params.tz, Option String));
           ("limit", Var (params.limit, Option Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_pull_requests = struct
  module Parameters = struct
    module Page = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      installation_id : string;
      page : Page.t option; [@default None]
      pr : int option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Pull_requests = struct
        type t = Terrat_api_components.Installation_pull_request.t list
        [@@deriving yojson { strict = false; meta = false }, show, eq]
      end

      type t = { pull_requests : Pull_requests.t }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Forbidden = struct end

    type t =
      [ `OK of OK.t
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson); ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v1/github/installations/{installation_id}/pull-requests"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("installation_id", Var (params.installation_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Option (Array String))); ("pr", Var (params.pr, Option Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_repos = struct
  module Parameters = struct
    module Page = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      installation_id : string;
      page : Page.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Repositories = struct
        type t = Terrat_api_components.Installation_repo.t list
        [@@deriving yojson { strict = false; meta = false }, show, eq]
      end

      type t = { repositories : Repositories.t }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Forbidden = struct end

    type t =
      [ `OK of OK.t
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson); ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v1/github/installations/{installation_id}/repos"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("installation_id", Var (params.installation_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Option (Array String))) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Repo_refresh = struct
  module Parameters = struct
    type t = { installation_id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = { id : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Forbidden = struct end

    type t =
      [ `OK of OK.t
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson); ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v1/github/installations/{installation_id}/repos/refresh"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("installation_id", Var (params.installation_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_work_manifests = struct
  module Parameters = struct
    module D = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Page = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      d : D.t option; [@default None]
      installation_id : string;
      limit : int option; [@default None]
      page : Page.t option; [@default None]
      q : string option; [@default None]
      tz : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Work_manifests = struct
        type t = Terrat_api_components.Installation_work_manifest.t list
        [@@deriving yojson { strict = false; meta = false }, show, eq]
      end

      type t = { work_manifests : Work_manifests.t }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Bad_request = struct
      type t = Terrat_api_components.Bad_request_err.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct end

    type t =
      [ `OK of OK.t
      | `Bad_request of Bad_request.t
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v1/github/installations/{installation_id}/work-manifests"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("installation_id", Var (params.installation_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Option (Array String)));
           ("q", Var (params.q, Option String));
           ("d", Var (params.d, Option String));
           ("tz", Var (params.tz, Option String));
           ("limit", Var (params.limit, Option Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_work_manifest = struct
  module Parameters = struct
    type t = {
      installation_id : string;
      work_manifest_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Terrat_api_components.Installation_work_manifest.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK of OK.t
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v1/github/installations/{installation_id}/work-manifests/{work_manifest_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("installation_id", Var (params.installation_id, String));
           ("work_manifest_id", Var (params.work_manifest_id, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Get_work_manifest_outputs = struct
  module Parameters = struct
    module Page = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      installation_id : string;
      limit : int option; [@default None]
      lite : bool; [@default false]
      page : Page.t option; [@default None]
      q : string option; [@default None]
      tz : string option; [@default None]
      work_manifest_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Steps = struct
        type t = Terrat_api_components.Installation_workflow_step_output.t list
        [@@deriving yojson { strict = false; meta = false }, show, eq]
      end

      type t = { steps : Steps.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Bad_request = struct
      type t = Terrat_api_components.Bad_request_err.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK of OK.t
      | `Bad_request of Bad_request.t
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v1/github/installations/{installation_id}/work-manifests/{work_manifest_id}/outputs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("installation_id", Var (params.installation_id, String));
           ("work_manifest_id", Var (params.work_manifest_id, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("q", Var (params.q, Option String));
           ("page", Var (params.page, Option (Array String)));
           ("tz", Var (params.tz, Option String));
           ("limit", Var (params.limit, Option Int));
           ("lite", Var (params.lite, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end
