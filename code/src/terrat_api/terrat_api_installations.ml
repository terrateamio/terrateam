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
      [@@deriving yojson { strict = true; meta = true }, show, eq]
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

  let url = "/api/v1/installations/{installation_id}/pull-requests"

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
      page : Page.t option; [@default None]
      pr : int option; [@default None]
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
      [@@deriving yojson { strict = true; meta = true }, show, eq]
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

  let url = "/api/v1/installations/{installation_id}/work-manifests"

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
           ("pr", Var (params.pr, Option Int));
           ("d", Var (params.d, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end
